param vnetId string
param adminUserName string
@secure()
param adminPasswordSecret string
param managementSubnetName string
param trustSubnetName string
param untrustSubnetName string
@maxValue(9)
param count int
param paloNamePrefix string
@allowed([
  'vmseries1'
  'vmseries-forms'
])
param planOffer string
@allowed([
  'bundle1'
  'bundle2'
  'byol'
])
param planName string
param imageVersion string = 'latest'
@allowed([
  'Standard_D3_v2'
  'Standard_D4_v2'
  'Standard_D5_v2'
  'Standard_D4_v3'
  'Standard_D16_v3'
  'Standard_DS3_v2'
  'Standard_DS4_v2'
  'Standard_DS5_v2'
])
param vmSize string
param managedIdentityId string

var plan = planOffer == 'vmseries-forms' ? 'bundle2-for-ms' : planName

var vnetIdSplit = split(vnetId, '/')
resource vnet 'Microsoft.Network/virtualNetworks@2020-11-01' existing = {
  name: vnetIdSplit[8]
  scope: resourceGroup(vnetIdSplit[4])
}

resource mgmtNic 'Microsoft.Network/networkInterfaces@2020-11-01' = [for i in range(0, count): {
  location: resourceGroup().location
  name: concat(paloNamePrefix, '-mgmt-nic-', i + 1)
  properties: {
    ipConfigurations: [
      {
        name: 'mgmt'
        properties: {
          subnet: {
            id: concat(vnet.id, '/subnets/', managementSubnetName)
          }
        }
      }
    ]
  }
}]

resource trust 'Microsoft.Network/networkInterfaces@2020-11-01' = [for i in range(0, count): {
  location: resourceGroup().location
  name: concat(paloNamePrefix, '-trust-nic-', i + 1)
  properties: {
    ipConfigurations: [
      {
        name: 'trust'
        properties: {
          subnet: {
            id: concat(vnet.id, '/subnets/', trustSubnetName)
          }
          loadBalancerBackendAddressPools: [
            {
              id: concat(trustLb.id,'/backendAddressPools/trust') 
            } 
          ] 
        }
      }
    ]
  }
}]

resource untrust 'Microsoft.Network/networkInterfaces@2020-11-01' = [for i in range(0, count): {
  location: resourceGroup().location
  name: concat(paloNamePrefix, '-untrust-nic-', i + 1)
  properties: {
    ipConfigurations: [
      {
        name: 'trust'
        properties: {
          subnet: {
            id: concat(vnet.id, '/subnets/', untrustSubnetName)
          }
          loadBalancerBackendAddressPools: [
            {
              id: concat(untrustLb.id,'/backendAddressPools/untrust') 
            } 
          ]
        }
      }
    ]
  }
}]

resource bootstrapStorage 'Microsoft.Storage/storageAccounts@2021-02-01' = {
  name: substring(concat('palo',replace(guid(paloNamePrefix,subscription().subscriptionId),'-','')),0,23)
  kind: 'StorageV2'
  location: resourceGroup().location
  sku: {
    name: 'Standard_LRS'
    tier: 'Standard'  
  }
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: true
    largeFileSharesState: 'Disabled'         
  }     
}

resource fileService 'Microsoft.Storage/storageAccounts/fileServices@2021-02-01' = {
  name: concat(bootstrapStorage.name,'/default')
  properties: {
  }  
}

resource fileShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2021-02-01' = {
  name: concat(fileService.name,'/palo') 
  properties: {
    accessTier: 'Cool'  
  }  
}

resource folderStructure 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  kind: 'AzurePowerShell'
  location: resourceGroup().location
  name: 'FolderCreate'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityId}':{}
    }  
  } 
  properties: {
    arguments: concat(bootstrapStorage.name,' ', resourceGroup().name, ' ', subscription().subscriptionId)
    scriptContent: 'Connect-AzAccount -Identity -Subscription $args[2];$storageAccount = Get-AzStorageAccount -Name $args[0] -ResourceGroupName $args[1];$context = $storageAccount.Context;get-AzStorageShare -Context $context -Name palo | New-AzStorageDirectory -Path "config" -ErrorAction SilentlyContinue;get-AzStorageShare -Context $context -Name palo | New-AzStorageDirectory -Path "content" -ErrorAction SilentlyContinue;get-AzStorageShare -Context $context -Name palo | New-AzStorageDirectory -Path "license" -ErrorAction SilentlyContinue;get-AzStorageShare -Context $context -Name palo | New-AzStorageDirectory -Path "software" -ErrorAction SilentlyContinue;$DeploymentScriptOutputs = @{};$DeploymentScriptOutputs[\'key\']=$storageAccount.Context.ConnectionString.Split(\';\')[5].Split(\'AccountKey=\')[1];'
    azPowerShellVersion: '5.9'
    retentionInterval: 'P1D'    
  } 
  dependsOn: [
    fileShare 
  ]    
}

var customData = concat('storage-account=',bootstrapStorage.name,',access-key=',folderStructure.properties.outputs.key,',file-share=palo,share-directory=')

resource paloAlto 'Microsoft.Compute/virtualMachines@2020-12-01' = [for i in range(0, count): {
  name: concat(paloNamePrefix, '-', i + 1)
  location: resourceGroup().location
  dependsOn: [
    folderStructure 
  ]
  plan: {
    publisher: 'paloaltonetworks'
    product: planOffer
    name: plan
  }
  zones: [
    string(i == 0 || i == 3 || i == 6 ? 1 : i == 1 || i == 4 || i == 7 ? 2 : 3)
  ]
  properties: {
    hardwareProfile: {
      vmSize: vmSize 
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: mgmtNic[i].id 
          properties: {
            primary: true 
          }
        }
        {
          id: untrust[i].id 
          properties: {
            primary: false 
          }
        }
        {
          id: trust[i].id 
          properties: {
            primary: false 
          }
        }  
      ] 
    }
    osProfile: {
      computerName: concat(paloNamePrefix, '-', i + 1)
      adminUsername: adminUserName
      adminPassword: adminPasswordSecret 
      linuxConfiguration: {}
      customData: base64(customData)  
    }
    storageProfile: {
      imageReference: {
        publisher: 'paloaltonetworks'
        offer: planOffer
        sku: plan
        version: imageVersion     
      }
      osDisk: {
        createOption: 'FromImage' 
      }  
    }   
  }  
}]

resource publicIp 'Microsoft.Network/publicIPAddresses@2020-11-01' = {
  name: 'palo-wan'
  location: resourceGroup().location
  sku: {
    name: 'Standard'
    tier: 'Regional'  
  }
  zones: [
    '1'
    '2'
    '3'
  ]
  properties: {
    publicIPAddressVersion: 'IPv4' 
    publicIPAllocationMethod: 'Static' 
  }   
}

resource untrustLb 'Microsoft.Network/loadBalancers@2020-11-01' = {
  name: 'Palo-Untrust'
  location: resourceGroup().location 
  sku: {
    name: 'Standard'
    tier: 'Regional'   
  }
  properties: {
    frontendIPConfigurations: [
      {
        name: 'Internet'
        properties: {
          publicIPAddress: {
            id: publicIp.id 
          } 
        }  
      }
    ]
    backendAddressPools: [
      {
        name: 'untrust'
        properties: {}
      }
    ]
    outboundRules: [
      {
        name: 'InternetNat'
        properties: {
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', 'Palo-Untrust', 'untrust') 
          }
          frontendIPConfigurations: [
            {
              id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', 'Palo-Untrust', 'Internet')  
            }
          ]
          protocol: 'All'
          enableTcpReset: true     
        }  
      } 
    ]    
  }    
}

resource trustLb 'Microsoft.Network/loadBalancers@2020-11-01' = {
  name: 'Palo-Trust'
  location: resourceGroup().location
  sku: {
    name: 'Standard'
    tier: 'Regional'   
  }
  properties: {
    frontendIPConfigurations: [
      {
        name: 'Trust'
        properties: {
          subnet: {
            id: concat(vnetId,'/subnets/',trustSubnetName) 
          } 
        }  
      }
    ]
    backendAddressPools: [
      {
        name: 'trust' 
        properties: {}  
      }
    ]
    outboundRules: []
    probes: [
      {
        name: 'trust'
        properties: {
          intervalInSeconds: 5
          numberOfProbes: 3
          port: 22
          protocol: 'Tcp'     
        }  
      }
    ]
    loadBalancingRules: [
      {
        name: 'HA'
        properties: {
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', 'Palo-Trust', 'trust') 
          }
          frontendPort: 0
          backendPort: 0
          protocol: 'All'
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', 'Palo-Trust', 'Trust')   
          }
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', 'Palo-Trust', 'trust') 
          }     
        }  
      } 
    ]     
  }    
}
