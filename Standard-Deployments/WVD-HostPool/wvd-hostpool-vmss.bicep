param splitTenant bool = false
param wvdTenantId string
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
param vmSize string = 'Standard_D4_v4'
param artifcatLocation string = 'https://location.com'

resource keyVault 'Microsoft.KeyVault/vaults@2021-04-01-preview' existing = {
  name: split(keyVaultSecretId,'/')[8]
  scope: resourceGroup(split(keyVaultSecretId,'/')[4]) 
}

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
        ] 
      }    
    }     
  }
}
