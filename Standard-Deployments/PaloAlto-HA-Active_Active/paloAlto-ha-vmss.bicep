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
  'vmseries-flex'
])
param planOffer string = 'vmseries-flex'
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
param location string = resourceGroup().location
param tags object = {}

var plan = planOffer == 'vmseries-forms' ? 'bundle2-for-ms' : planName

var vnetIdSplit = split(vnetId, '/')
resource vnet 'Microsoft.Network/virtualNetworks@2020-11-01' existing = {
  name: vnetIdSplit[8]
  scope: resourceGroup(vnetIdSplit[4])
}

resource bootstrapStorage 'Microsoft.Storage/storageAccounts@2021-02-01' = {
  name: substring(concat('palo',replace(guid(paloNamePrefix,subscription().subscriptionId),'-','')),0,23)
  kind: 'StorageV2'
  location: location
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

module init 'init-cfg.bicep' = {
  name: 'Build-Init-cfg'
}

var trustSubnetAddress = split(split(reference(concat(vnet.id, '/subnets/', trustSubnetName),'2020-11-01', 'Full').properties.addressPrefix,'/')[0],'.')
var trustDefaultGateway = concat(trustSubnetAddress[0],'.',trustSubnetAddress[1],'.',trustSubnetAddress[2],'.',string(int(trustSubnetAddress[3])+1))

var untrustSubnetAddress = split(split(reference(concat(vnet.id, '/subnets/', untrustSubnetName),'2020-11-01', 'Full').properties.addressPrefix,'/')[0],'.')
var untrustDefaultGateway = concat(untrustSubnetAddress[0],'.',untrustSubnetAddress[1],'.',untrustSubnetAddress[2],'.',string(int(untrustSubnetAddress[3])+1))
module bootstrapXml 'bootstrapxml.bicep' = {
  name: 'Build-BootstrapConfig'
  params: {
    trustGateway: trustDefaultGateway
    untrustGateway: untrustDefaultGateway 
  }  
}

resource folderStructure 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  kind: 'AzurePowerShell'
  location: location
  name: 'FolderCreate'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityId}':{}
    }  
  } 
  properties: {
    arguments: concat(bootstrapStorage.name,' ', resourceGroup().name, ' ', subscription().subscriptionId, ' @\'\n', bootstrapXml.outputs.bootstrapXml,'\n\'@', ' @\'\n', init.outputs.cfg,'\n\'@')
    scriptContent: 'Connect-AzAccount -Identity -Subscription $args[2];$storageAccount = Get-AzStorageAccount -Name $args[0] -ResourceGroupName $args[1];$context = $storageAccount.Context;get-AzStorageShare -Context $context -Name palo | New-AzStorageDirectory -Path "config" -ErrorAction SilentlyContinue;get-AzStorageShare -Context $context -Name palo | New-AzStorageDirectory -Path "content" -ErrorAction SilentlyContinue;get-AzStorageShare -Context $context -Name palo | New-AzStorageDirectory -Path "license" -ErrorAction SilentlyContinue;get-AzStorageShare -Context $context -Name palo | New-AzStorageDirectory -Path "software" -ErrorAction SilentlyContinue;$args[4] |Out-File -Path init-cfg.txt;$args[3] | Out-File -Path bootstrap.xml;get-AzStorageShare -Context $context -Name palo | Set-AzStorageFileContent -Path /config -Source .\\init-cfg.txt -Force -Confirm:$false;get-AzStorageShare -Context $context -Name palo | Set-AzStorageFileContent -Path /config -Source .\\bootstrap.xml -Force -Confirm:$false;$DeploymentScriptOutputs = @{};$DeploymentScriptOutputs[\'key\']=$storageAccount.Context.ConnectionString.Split(\';\')[5].Split(\'AccountKey=\')[1];'
    azPowerShellVersion: '5.9'
    retentionInterval: 'P1D'    
  } 
  dependsOn: [
    fileShare 
  ]    
}

var customData = concat('storage-account=',bootstrapStorage.name,',access-key=',folderStructure.properties.outputs.key,',file-share=palo,share-directory=')
var zones = location == 'eastus' || location == 'eastus2' || location == 'centralus' || location == 'southcentralus' || location == 'westus2' || location == 'usgovvirginia' ? [
  '1'
  '2'
  '3'
] : []

var zoneLb = zones == [] ? false : true

resource paloAltoSet 'Microsoft.Compute/virtualMachineScaleSets@2020-12-01' = {
  name: paloNamePrefix
  location: location
  plan: {
    publisher: 'paloaltonetworks'
    product: planOffer
    name: plan
  }
  dependsOn: [
    folderStructure
  ]
  sku: {
     capacity: count
     tier: 'Standard'
     name: vmSize    
  }
  zones: zones 
  tags: tags 
  properties: {
    upgradePolicy: {
      mode: 'Rolling'
      automaticOSUpgradePolicy: {
        enableAutomaticOSUpgrade: false 
      } 
      rollingUpgradePolicy: {
        prioritizeUnhealthyInstances: true
        enableCrossZoneUpgrade: true  
      }  
    } 
    zoneBalance: zoneLb
    virtualMachineProfile: { 
      osProfile: {
        computerNamePrefix: paloNamePrefix 
        adminUsername: adminUserName
        adminPassword: adminPasswordSecret 
        linuxConfiguration: {}
        customData: base64(customData)  
      }
      networkProfile: {
        healthProbe: {
          id: resourceId('Microsoft.Network/loadBalancers/probes', concat('Palo-Trust-',paloNamePrefix), 'trust') 
        } 
        networkInterfaceConfigurations: [
          {
            name: 'mgmt-nic'
            properties: {
              ipConfigurations: [
                {
                  name: 'mgmt'
                  properties: {
                    subnet: {
                      id: concat(vnet.id, '/subnets/', managementSubnetName)
                    }
                    loadBalancerBackendAddressPools: [
                      {
                        id: concat(trustLb.id,'/backendAddressPools/mgmt') 
                      } 
                    ] 
                  }
                }
              ]              
              primary: true 
            } 
          }
          {
            name: 'untrust-nic'
            properties: {
              enableIPForwarding: true 
              enableAcceleratedNetworking: true 
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
          }
          {
            name: 'trust-nic'
            properties: {
              enableIPForwarding: true
              enableAcceleratedNetworking: true 
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
          }
        ]   
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
      diagnosticsProfile: {
        bootDiagnostics: {
          enabled: true
          storageUri: bootstrapStorage.properties.primaryEndpoints.blob  
        } 
      }       
    }    
  }   
}

resource publicIp 'Microsoft.Network/publicIPAddresses@2020-11-01' = {
  name: 'palo-wan'
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'  
  }
  zones: zones
  properties: {
    publicIPAddressVersion: 'IPv4' 
    publicIPAllocationMethod: 'Static' 
  }   
}

resource untrustLb 'Microsoft.Network/loadBalancers@2020-11-01' = {
  name: concat('Palo-Untrust-',paloNamePrefix)
  location: location 
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
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', concat('Palo-Untrust-',paloNamePrefix), 'untrust') 
          }
          frontendIPConfigurations: [
            {
              id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', concat('Palo-Untrust-',paloNamePrefix), 'Internet')  
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
  name: concat('Palo-Trust-',paloNamePrefix)
  location: location
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
      {
        name: 'Mgmt'
        properties: {
          subnet: {
            id: concat(vnetId,'/subnets/',managementSubnetName) 
          } 
        }  
      }
    ]
    backendAddressPools: [
      {
        name: 'trust' 
        properties: {}  
      }
      {
        name: 'mgmt' 
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
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', concat('Palo-Trust-',paloNamePrefix), 'trust') 
          }
          frontendPort: 0
          backendPort: 0
          protocol: 'All'
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', concat('Palo-Trust-',paloNamePrefix), 'Trust')   
          }
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', concat('Palo-Trust-',paloNamePrefix), 'trust') 
          }     
        }  
      }
      {
        name: 'Mgmt'
        properties: {
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', concat('Palo-Trust-',paloNamePrefix), 'mgmt') 
          }
          frontendPort: 22
          backendPort: 22
          protocol: 'Tcp'
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', concat('Palo-Trust-',paloNamePrefix), 'Mgmt')   
          }
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', concat('Palo-Trust-',paloNamePrefix), 'trust') 
          }     
        }  
      }  
    ]     
  }    
}
