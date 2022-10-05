param scaleSetName string
@maxLength(9)
@minLength(3)
param vmPrefix string
param newScaleSet bool = false
param scaleExisting bool = true
@maxValue(1000)
@minValue(1)
param vmCount int = 1
param vmSize string
param customImage bool = false
param customImageResourceId string = ''
param imageOffer string = ''
param imagePublisher string = ''
param imageSku string = ''
param localadminUsername string
@secure()
param localadminPassword string
param domainJoinUsername string
@secure()
param domainJoinPassword string
param domainFqdn string
param ouPath string
param location string
param hostpoolResourceId string
param managedIdentityId string
param virtualNetworkId string
param subnetName string
param useAvailabilityZones bool
param tags object = {}

var hostPoolName = split(hostpoolResourceId,'/')[8]
var hostPoolResourceGroup = split(hostpoolResourceId,'/')[4]
var azRegions = [
  'eastus'
  'eastus2'
  'centralus'
  'southcentralus'
  'usgovvirginia'
  'westus2'
  'westus3'
]

var zones = contains(azRegions, location) ? [
  '1'
  '2'
  '3'
] : []

var zoneBalance = zones == [] && useAvailabilityZones == true ? false : true

var removeHostsFromScaleSetArgs = '-scaleset ${scaleSetName} -resourceGroup ${resourceGroup().name} -subscription ${subscription().subscriptionId}'
module removeHostsFromScaleSet '../../Modules/Microsoft.Resources/deploymentScripts/deploymentScripts-powershell.bicep' = if(newScaleSet == false && scaleExisting == false){
  name: 'Remove-VMs-From-${scaleSetName}'
  params: {
    arguments: removeHostsFromScaleSetArgs
    managedIdentityId: managedIdentityId  
    name: 'Remove-VMs-${scaleSetName}' 
    pscriptUri: 'https://raw.githubusercontent.com/lukearp/Azure-IAC-Bicep/master/Scripts/Remove-VMScaleSet/Remove-VMScaleSet.ps1'
    location: location 
  }
}

var removeHostsFromPoolArgs = newScaleSet == false ? '-vms ${json(string(removeHostsFromScaleSet.outputs.results)).computerNames} -hostpoolName ${hostPoolName} -hostpoolResourceGroup ${hostPoolResourceGroup} -subscription ${subscription().subscriptionId}' : ''
module removeHostsFromPool '../../Modules/Microsoft.Resources/deploymentScripts/deploymentScripts-powershell.bicep' = if(newScaleSet == false && scaleExisting == false){
  name: 'Remove-VMs-${hostPoolName}-${scaleSetName}' 
  scope: resourceGroup(split(hostpoolResourceId,'/')[4]) 
  params: {
    arguments: removeHostsFromPoolArgs
    managedIdentityId: managedIdentityId  
    name: 'Remove-Hosts-${scaleSetName}' 
    pscriptUri: 'https://raw.githubusercontent.com/lukearp/Azure-IAC-Bicep/master/Scripts/Remove-VMsFromAVDHostPool/Remove-VMsFromAVDHostPool.ps1'
    location: location    
  } 
}

//var getHostRegistrationKeyArgs = splitTenant == true ? '-splitTenant $true -appId ${wvdAppId} -tenantId ${wvdTenantId} -keyVaultName ${keyVaultName} -secretName ${keyVaultSecretName} -hostPoolResourceId ${hostPoolResourceId}' : '-splitTenant $false -appId ${wvdAppId} -tenantId ${wvdTenantId} -keyVaultName ${keyVaultName} -secretName ${keyVaultSecretName} -hostPoolResourceId ${hostPoolResourceId}'
var getHostRegistrationKeyArgs = '-splitTenant $false -appId $null -tenantId $null -keyVaultName $null -secretName $null -hostPoolResourceId ${hostpoolResourceId}'

module hostpoolRegistration '../../Modules/Microsoft.Resources/deploymentScripts/deploymentScripts-powershell.bicep' = {
  name: 'GetRegistrionTokey-${hostPoolName}'
  params: {
    arguments: getHostRegistrationKeyArgs
    location: location
    managedIdentityId: managedIdentityId
    name: 'Get-WVD-Key'
    pscriptUri: 'https://raw.githubusercontent.com/lukearp/Azure-IAC-Bicep/master/Scripts/WVD-HostPool-Key/WVD-HostPool-RegistrationKey.ps1'       
  } 
}

var vmssProperties = customImage == false ? {
  zoneBalance: zoneBalance
  upgradePolicy: {
    mode: 'Manual'
  }
  platformFaultDomainCount: zoneBalance == true ? 1 : 3
  orchestrationMode: 'Uniform'
  singlePlacementGroup: false
  overprovision: false
  virtualMachineProfile: {
    licenseType: 'Windows_Client' 
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true 
      } 
    }
    osProfile: {
      adminPassword: localadminPassword
      adminUsername: localadminUsername
      computerNamePrefix: vmPrefix     
      windowsConfiguration: {
        enableAutomaticUpdates: true 
        provisionVMAgent: true             
      } 
    }
    storageProfile: {
      imageReference: {
        offer: imageOffer
        publisher: imagePublisher
        sku: imageSku
        version: 'latest'    
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS' 
        }    
      }  
    }
    networkProfile: {
      networkInterfaceConfigurations: [
        {
          name: 'nic'
          properties: {
            primary: true
            ipConfigurations: [
              {
                name: 'ipconfig'
                properties: {
                  subnet: {
                    id: '${virtualNetworkId}/subnets/${subnetName}' 
                  } 
                }  
              }
            ]  
          }  
        } 
      ]   
    }
    extensionProfile: {
      extensions: [
        {
           name: 'HealthExtension' 
           properties: {
             publisher: 'Microsoft.ManagedServices'
             type: 'ApplicationHealthWindows'
             autoUpgradeMinorVersion: true
             typeHandlerVersion: '1.0'
             settings: {
               protocol: 'tcp'
               port: 3389 
             }    
           }   
        }          
        {
          name: 'AVD-Setup'
          properties: {
            provisionAfterExtensions: [
              'HealthExtension'
            ]
            publisher: 'Microsoft.Powershell'
            type: 'DSC'
            autoUpgradeMinorVersion: true
            typeHandlerVersion: '2.73'
            settings: {
              modulesUrl: 'https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration_08-10-2022.zip'
              configurationFunction: 'Configuration.ps1\\AddSessionHost'
              properties: {
                hostPoolName: hostPoolName
                registrationInfoToken: json(string(hostpoolRegistration.outputs.results)).registrationKey
                aadJoin: false
                UseAgentDownloadEndpoint: true
                aadJoinPreview: false
                mdmId: ''
                sessionHostConfigurationLastUpdateTime: ''
              }
            }  
          }
        }
        {
          name: 'DomainJoin' 
          properties: {
            provisionAfterExtensions: [
              'AVD-Setup'
            ]
            publisher: 'Microsoft.Compute' 
            type: 'JsonADDomainExtension'  
            typeHandlerVersion: '1.3'
            autoUpgradeMinorVersion: true
            settings: {
              name: domainFqdn
              ouPath: ouPath
              user: domainJoinUsername
              restart: 'true'
              options: 3
            }
            protectedSettings: {
              password: domainJoinPassword
            }
          } 
        } 
      ] 
    }    
  }     
} : {
  zoneBalance: zoneBalance
  upgradePolicy: {
    mode: 'Manual'
  }
  platformFaultDomainCount: zoneBalance == true ? 1 : 3
  orchestrationMode: 'Uniform'
  singlePlacementGroup: false
  overprovision: false
  virtualMachineProfile: {
    licenseType: 'Windows_Client' 
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true 
      } 
    }
    osProfile: {
      adminPassword: localadminPassword
      adminUsername: localadminUsername
      computerNamePrefix: vmPrefix     
      windowsConfiguration: {
        enableAutomaticUpdates: true 
        provisionVMAgent: true             
      } 
    }
    storageProfile: {
      imageReference: {
        id: customImageResourceId   
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS' 
        }    
      }  
    }
    networkProfile: {
      networkInterfaceConfigurations: [
        {
          name: 'nic'
          properties: {
            primary: true
            ipConfigurations: [
              {
                name: 'ipconfig'
                properties: {
                  subnet: {
                    id: '${virtualNetworkId}/subnets/${subnetName}' 
                  } 
                }  
              }
            ]  
          }  
        } 
      ]   
    }
    extensionProfile: {
      extensions: [
        {
           name: 'HealthExtension' 
           properties: {
             publisher: 'Microsoft.ManagedServices'
             type: 'ApplicationHealthWindows'
             autoUpgradeMinorVersion: true
             typeHandlerVersion: '1.0'
             settings: {
               protocol: 'tcp'
               port: 3389 
             }    
           }   
        }          
        {
          name: 'AVD-Setup'
          properties: {
            provisionAfterExtensions: [
              'HealthExtension'
            ]
            publisher: 'Microsoft.Powershell'
            type: 'DSC'
            autoUpgradeMinorVersion: true
            typeHandlerVersion: '2.73'
            settings: {
              modulesUrl: 'https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration_08-10-2022.zip'
              configurationFunction: 'Configuration.ps1\\AddSessionHost'
              properties: {
                hostPoolName: hostPoolName
                registrationInfoToken: json(string(hostpoolRegistration.outputs.results)).registrationKey
                aadJoin: false
                UseAgentDownloadEndpoint: true
                aadJoinPreview: {
                  hostpoolUpdateFeature: false
                  aadJoinPreview: false 
                  sessionHostConfigurationVersion: ''
                }
                mdmId: ''
                sessionHostConfigurationLastUpdateTime: ''
              }
            }  
          }
        }
        {
          name: 'DomainJoin' 
          properties: {
            provisionAfterExtensions: [
              'AVD-Setup'
            ]
            publisher: 'Microsoft.Compute' 
            type: 'JsonADDomainExtension'  
            typeHandlerVersion: '1.3'
            autoUpgradeMinorVersion: true
            settings: {
              name: domainFqdn
              ouPath: ouPath
              user: domainJoinUsername
              restart: 'true'
              options: 3
            }
            protectedSettings: {
              password: domainJoinPassword
            }
          } 
        } 
      ] 
    }    
  }     
}

resource hostPool 'Microsoft.Compute/virtualMachineScaleSets@2021-03-01' = {
  name: scaleSetName
  identity: {
    type: 'SystemAssigned' 
  }
  dependsOn: [
    removeHostsFromPool
    hostpoolRegistration
  ]
  location: location
  sku: {
    capacity: vmCount 
    tier: 'Standard'
    name: vmSize  
  }/*
  plan: {
   publisher: imagePublisher
   product: imageOffer
   name: imageSku      
  }*/
  zones: zones 
  properties: vmssProperties
  tags: tags 
}

