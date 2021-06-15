param splitTenant bool = false
param wvdTenantId string
param wvdAppId string
param keyVaultName string
param keyVaultSecretName string
param hostPoolName string
@maxLength(10)
param vmNamePrefix string
param hostPoolResourceGroupName string
param hostPoolSubscription string
param profileContainerPath string
param userManagedIdentityId string
param hostCount int
@allowed([
  'MicrosoftWindowsDesktop'
])
param imagePublisher string
@allowed([
  'office-365'
])
param imageOffer string
@allowed([
 '19h2-evd-o365pp'
 '20h1-evd-o365pp'
 '21h1-evd-o365pp'
])
param imageSku string
param virtualNetworkId string
param subnetName string
param location string = resourceGroup().location
param adminUsername string
@secure()
param adminPassword string
param domainJoinUsername string
@secure()
param domainJoinPassword string
param domainFqdn string
param ouPath string
param vmSize string = 'Standard_D4_v4'
param artifcatLocation string = 'https://github.com/lukearp/Azure-IAC-Bicep/releases/download/DSC/WVD-DSC.zip'

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

var zoneBalance = zones == [] ? false : true
var hostPoolResourceId = '/subscriptions/${hostPoolSubscription}/resourceGroups/${hostPoolResourceGroupName}/providers/Microsoft.DesktopVirtualization/hostpools/${hostPoolName}'
var getHostRegistrationKeyArgs = splitTenant == true ? '-splitTenant $true -appId ${wvdAppId} -tenantId ${wvdTenantId} -keyVaultName ${keyVaultName} -secretName ${keyVaultSecretName} -hostPoolResourceId ${hostPoolResourceId}' : '-splitTenant $false -appId ${wvdAppId} -tenantId ${wvdTenantId} -keyVaultName ${keyVaultName} -secretName ${keyVaultSecretName} -hostPoolResourceId ${hostPoolResourceId}'

module deploymentScript '../../Modules/Microsoft.Resources/deploymentScripts/deploymentScripts-powershell.bicep' = {
  name: 'scriptTest'
  params: {
    arguments: getHostRegistrationKeyArgs
    location: resourceGroup().location
    managedIdentityId: userManagedIdentityId
    name: 'Get-WVD-Key'
    pscriptUri: 'https://raw.githubusercontent.com/lukearp/Azure-IAC-Bicep/WVD-Hostpool-StandardDeploy/Scripts/WVD-HostPool-Key/WVD-HostPool-RegistrationKey.ps1'       
  } 
}

resource hostPool 'Microsoft.Compute/virtualMachineScaleSets@2021-03-01' = {
  name: hostPoolName
  identity: {
    type: 'SystemAssigned' 
  }
  location: location
  sku: {
    capacity: hostCount 
    tier: 'Standard'
    name: vmSize  
  }
  plan: {
   publisher: imagePublisher
   product: imageOffer
   name: imageSku      
  }
  zones: zones 
  properties: {
    zoneBalance: zoneBalance
    upgradePolicy: {
      mode: 'Manual' 
    }
     
    overprovision: false
    virtualMachineProfile: {
      licenseType: 'Windows_Client' 
      diagnosticsProfile: {
        bootDiagnostics: {
          enabled: true 
        } 
      }
      osProfile: {
        adminPassword: adminPassword
        adminUsername: adminUsername
        computerNamePrefix: vmNamePrefix    
        windowsConfiguration: {
          patchSettings: {
            patchMode: 'AutomaticByPlatform'
            enableHotpatching: true  
          } 
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
        networkApiVersion: '2020-11-01'
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
            name: 'DSC-Setup'
            properties: {
              provisionAfterExtensions: [
                'HealthExtension'
              ]
              publisher: 'Microsoft.Powershell'
              type: 'DSC'
              autoUpgradeMinorVersion: true
              typeHandlerVersion: '2.73'
              settings: {
                modulesUrl: artifcatLocation
                configurationFunction: 'Configuration.ps1\\AddSessionHost'
                properties: {
                  hostPoolName: hostPoolName
                  registrationInfoToken: json(string(deploymentScript.outputs.results)).registrationKey
                  uncPath: profileContainerPath
                }
              }  
            }
          }
          {
            name: 'DomainJoin' 
            properties: {
              provisionAfterExtensions: [
                'DSC-Setup'
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
}
