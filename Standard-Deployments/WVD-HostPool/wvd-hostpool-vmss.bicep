param splitTenant bool = false
param wvdTenantId string
param wvdAppId string
param keyVaultSecretId string
param hostPoolName string
param hostPoolResourceGroupName string
param hostPoolSubscription string
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
param artifcatLocation string = 'https://location.com'

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
//Add logic for Split Tenant and Non-Split Tenant
module deploymentScript '../../Modules/Microsoft.Resources/deploymentScripts/deploymentScripts-powershell.bicep' = {
  name: 'scriptTest'
  params: {
    arguments: '-appId de23617f-7644-4f65-8faa-8708bccdfc1d -tenantId ef3caa26-9b3d-48f1-9434-eaff760575c4 -keyVaultName ase-test-bcf48574b4a4ce8 -secretName wvd-test -hostPoolResourceId /subscriptions/2ab6855d-b9f8-4762-bba5-efe49f339629/resourceGroups/rg_wvd_spring/providers/Microsoft.DesktopVirtualization/hostpools/VM-SS'
    location: 'eastus'
    managedIdentityId: '/subscriptions/4bb3900a-62d5-41a8-a02c-1b811cf079c7/resourceGroups/user-identities/providers/Microsoft.ManagedIdentity/userAssignedIdentities/template-spec'
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
        computerNamePrefix: hostPoolName    
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
                  registrationInfoToken: 
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
