param splitTenant bool = false
param wvdTenantId string
param keyVaultSecretId string
param hostPoolName string
param hostPoolResourceGroupName string
param hostPoolSubscription string
param hostCount int
param imagePublisher string
param imageOffer string
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
      extensionProfile: {
        extensions: [
          {
             
          } 
        ] 
      }    
    }     
  }
}
