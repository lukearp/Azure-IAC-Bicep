targetScope = 'subscription'

param resourceGroupName string
param mlWorkspaceName string
param location string
param enableDiagnostics bool = false
param logAnalyticsResourceId string = ''
param azureGovernment bool = false
param tags object = {}

var storageSuffix = azureGovernment == false ? 'core.windows.net' : 'core.usgovcloudapi.net'
var acrPrivateDns = azureGovernment == false ? 'privatelink.azurecr.io' : 'privatelink.azurecr.us'
var keyvaultDns = azureGovernment == false ? 'privatelink.vaultcore.azure.net' : 'privatelink.vault.usgovcloudapi.net'
var mlApiDns = azureGovernment == false ? 'privatelink.api.azureml.ms' : 'privatelink.api.ml.azure.us'
var mlNotbookDns = azureGovernment == false ? 'privatelink.notebooks.azure.net' : 'privatelink.notebooks.usgovcloudapi.net'
var suffix = substring(replace(guid('${resourceGroupName}-${location}-${subscription().id}'),'-',''),0,15)

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

module storage '../../Modules/Microsoft.Storage/storageAccounts/storageAccounts.bicep' = {
   name: '${mlWorkspaceName}-StorageDeployment'
   scope: resourceGroup(rg.name)
   params: {
    kind: 'StorageV2'
    location: location
    accessTier: 'Hot'
    sku: 'Standard_LRS'
    name: 'ml${suffix}'
    enableDiagnostics: enableDiagnostics
    workspaceId: logAnalyticsResourceId  
    enableHierarchicalNamespace: false 
    disablePubliAccess: true
    supportsHttpsTrafficOnly: true   
    tags: tags    
   } 
}

module keyvault '../../Modules/Microsoft.KeyVaults/vaults.bicep' = {
  name: '${mlWorkspaceName}-KeyVault'
  scope: resourceGroup(rg.name)
  params: {
    location: location
    name: 'kv${suffix}'
    tags: tags  
    enableSoftDelete: true     
  }  
}

module acr '../../Modules/Microsoft.ContainerRegistry/registries.bicep' = {
  name: '${mlWorkspaceName}-ContainerRegistry'
  scope: resourceGroup(rg.name) 
  params: {
    name: 'acr${suffix}'
    location: location
    sku: 'Premium' 
    tags: tags    
  } 
}

module vnet '../../Modules/Microsoft.Network/virtualNetworks/virtualNetworks.bicep' = {
  name: '${mlWorkspaceName}-VirtualNetwork'
  scope: resourceGroup(rg.name) 
  params: {
    location: location 
    tags: tags 
    networkSecurityGroups: [] 
    vnetAddressSpaces: [
      '10.160.48.0/24'
    ] 
    vnetName: 'vn${suffix}' 
    vnetDnsServers: []
    vnetSubnets: [
      {
        name: 'PrivateLink'
        addressPrefix: '10.160.48.0/26'
      }
      {
        name: 'Train'
        addressPrefix: '10.160.48.64/26'
      }
      {
        name: 'Score'
        addressPrefix: '10.160.48.128/26'
      }
      {
        name: 'AVD'
        addressPrefix: '10.160.48.192/26'
      }
    ]  
  }
}

module appInsights '../../Modules/Microsoft.Insights/components.bicep' = {
  name: '${mlWorkspaceName}-AppInsights' 
  scope: resourceGroup(rg.name)
  params: {
    name: 'ap${suffix}'
    location: location
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
    tags: tags     
  }
}

module mlworkspace '../../Modules/Microsoft.MachineLearningServices/workspaces.bicep' = {
  name: '${mlWorkspaceName}-Deployment'
  scope: resourceGroup(rg.name)
  params: {
    containerRegisteryId: acr.outputs.acrId
    identity: 'SystemAssigned'
    keyVaultId: keyvault.outputs.keyVaultId
    location: location
    name: mlWorkspaceName
    storageAccountId: storage.outputs.storageAccountId
    publicNetworkAccess: 'Enabled'
    tags: tags
    tier: 'Basic'
    v1LegacyMode: false
    applicationInsightsId: appInsights.outputs.appInsightId             
  }  
}

module mlworkspacePrivateLink '../../Modules/Microsoft.Network/privateEndpoints/privateEndpoints.bicep' = {
  name: '${mlWorkspaceName}-mlWorkspacePL'
  scope: resourceGroup(rg.name) 
  params: {
    location: location
    name: '${mlWorkspaceName}-mlPL'
    remoteServiceResourceId: mlworkspace.outputs.mlWorkspaceId
    subnetResourceId: '${vnet.outputs.resourceId}/subnets/PrivateLink'
    targetSubResource: [
      'amlworkspace'
    ] 
    manual: false
    requestMessage: 'AutoDeploy'      
  } 
}

module storagePrivateLinkBlob '../../Modules/Microsoft.Network/privateEndpoints/privateEndpoints.bicep' = {
  name: '${mlWorkspaceName}-StorageBlobPL'
  scope: resourceGroup(rg.name) 
  params: {
    location: location
    name: '${mlWorkspaceName}-StorageBlobPL'
    remoteServiceResourceId: storage.outputs.storageAccountId
    subnetResourceId: '${vnet.outputs.resourceId}/subnets/PrivateLink'
    targetSubResource: [
      'blob'
    ] 
    manual: false
    requestMessage: 'AutoDeploy'      
  } 
}

module storagePrivateLinkFile '../../Modules/Microsoft.Network/privateEndpoints/privateEndpoints.bicep' = {
  name: '${mlWorkspaceName}-StorageFilePL'
  scope: resourceGroup(rg.name) 
  params: {
    location: location
    name: '${mlWorkspaceName}-StorageFilePL'
    remoteServiceResourceId: storage.outputs.storageAccountId
    subnetResourceId: '${vnet.outputs.resourceId}/subnets/PrivateLink'
    targetSubResource: [
      'file'
    ] 
    manual: false
    requestMessage: 'AutoDeploy'      
  } 
}

module storagePrivateLinkDfs '../../Modules/Microsoft.Network/privateEndpoints/privateEndpoints.bicep' = {
  name: '${mlWorkspaceName}-StorageDfsPL'
  scope: resourceGroup(rg.name) 
  params: {
    location: location
    name: '${mlWorkspaceName}-StorageDfsPL'
    remoteServiceResourceId: storage.outputs.storageAccountId
    subnetResourceId: '${vnet.outputs.resourceId}/subnets/PrivateLink'
    targetSubResource: [
      'dfs'
    ] 
    manual: false
    requestMessage: 'AutoDeploy'      
  } 
}

module keyvaultPrivateLink '../../Modules/Microsoft.Network/privateEndpoints/privateEndpoints.bicep' = {
  name: '${mlWorkspaceName}-KeyVaultPL'
  scope: resourceGroup(rg.name) 
  params: {
    location: location
    name: '${mlWorkspaceName}-KeyVaultPL'
    remoteServiceResourceId: keyvault.outputs.keyVaultId
    subnetResourceId: '${vnet.outputs.resourceId}/subnets/PrivateLink'
    targetSubResource: [
      'vault'
    ] 
    manual: false
    requestMessage: 'AutoDeploy'       
  } 
}

module acrPrivateLink '../../Modules/Microsoft.Network/privateEndpoints/privateEndpoints.bicep' = {
  name: '${mlWorkspaceName}-AcrPL'
  scope: resourceGroup(rg.name)
  params: {
    location: location
    name: '${mlWorkspaceName}-AcrPL'
    remoteServiceResourceId: acr.outputs.acrId
    subnetResourceId: '${vnet.outputs.resourceId}/subnets/PrivateLink'
    manual: false
    requestMessage: 'AutoDeploy'
    targetSubResource: [
      'registry'
    ]       
  }    
}

module blobDNSZone '../../Modules/Microsoft.Network/privateDnsZones/privateDnsZones.bicep' = {
  name: '${mlWorkspaceName}-BlobDNSZone' 
  scope: resourceGroup(rg.name)
  params: {
    zoneName: 'privatelink.blob.${storageSuffix}' 
    createARecord: true
    aRecordName: split(storage.outputs.storageAccountId,'/')[8]  
    aRecordIp: storagePrivateLinkBlob.outputs.customerDnsConfigs[0].ipAddresses[0] 
    vnetAssociations: [
      {
        id: vnet.outputs.resourceId
        registrationEnabled: false
      }
    ]
  }
}

module fileDNSZone '../../Modules/Microsoft.Network/privateDnsZones/privateDnsZones.bicep' = {
  name: '${mlWorkspaceName}-FileDNSZone' 
  scope: resourceGroup(rg.name)
  params: {
    zoneName: 'privatelink.file.${storageSuffix}' 
    createARecord: true
    aRecordName: split(storage.outputs.storageAccountId,'/')[8]  
    aRecordIp: storagePrivateLinkFile.outputs.customerDnsConfigs[0].ipAddresses[0]
    vnetAssociations: [
      {
        id: vnet.outputs.resourceId
        registrationEnabled: false
      }
    ]
  }
}

module dfsDNSZone '../../Modules/Microsoft.Network/privateDnsZones/privateDnsZones.bicep' = {
  name: '${mlWorkspaceName}-DfsDNSZone' 
  scope: resourceGroup(rg.name)
  params: {
    zoneName: 'privatelink.dfs.${storageSuffix}' 
    createARecord: true
    aRecordName: split(storage.outputs.storageAccountId,'/')[8]  
    aRecordIp: storagePrivateLinkDfs.outputs.customerDnsConfigs[0].ipAddresses[0]
    vnetAssociations: [
      {
        id: vnet.outputs.resourceId
        registrationEnabled: false
      }
    ]
  }
}

module keyvaultDNSZone '../../Modules/Microsoft.Network/privateDnsZones/privateDnsZones.bicep' = {
  name: '${mlWorkspaceName}-KeyVaultDNSZone' 
  scope: resourceGroup(rg.name)
  params: {
    zoneName: keyvaultDns 
    createARecord: true
    aRecordName: split(keyvault.outputs.keyVaultId,'/')[8]  
    aRecordIp: keyvaultPrivateLink.outputs.customerDnsConfigs[0].ipAddresses[0]
    vnetAssociations: [
      {
        id: vnet.outputs.resourceId
        registrationEnabled: false
      }
    ]
  }
}

module acrDNSZone '../../Modules/Microsoft.Network/privateDnsZones/privateDnsZones.bicep' = {
  name: '${mlWorkspaceName}-AcrDNSZone' 
  scope: resourceGroup(rg.name)
  params: {
    zoneName: acrPrivateDns 
    createARecord: true
    aRecordName: split(acr.outputs.acrId,'/')[8]  
    aRecordIp: acrPrivateLink.outputs.customerDnsConfigs[0].ipAddresses[0]
    vnetAssociations: [
      {
        id: vnet.outputs.resourceId
        registrationEnabled: false
      }
    ]
  }
}

module mlApiDnsZone '../../Modules/Microsoft.Network/privateDnsZones/privateDnsZones.bicep' = {
  name: '${mlWorkspaceName}-mlApiDnsZone' 
  scope: resourceGroup(rg.name)
  params: {
    zoneName: mlApiDns 
    createARecord: false
    vnetAssociations: [
      {
        id: vnet.outputs.resourceId
        registrationEnabled: false
      }
    ]
  }
}

module mlNotebookDnsZone '../../Modules/Microsoft.Network/privateDnsZones/privateDnsZones.bicep' = {
  name: '${mlWorkspaceName}-mlNotebookDnsZone' 
  scope: resourceGroup(rg.name)
  params: {
    zoneName: mlNotbookDns 
    createARecord: false
    vnetAssociations: [
      {
        id: vnet.outputs.resourceId
        registrationEnabled: false
      }
    ]
  }
}

module mlRecords 'dnsrecordLoop.bicep' = {
  name: 'Create-ML-DNS-Records'
  scope: resourceGroup(rg.name)
  dependsOn: [
    mlApiDnsZone
    mlNotebookDnsZone
  ]
  params: {
    records: mlworkspacePrivateLink.outputs.customerDnsConfigs
    azureGovernment: azureGovernment
  }
}

module hostPool '../../Modules/Microsoft.DesktopVirtualization/hostpools.bicep' = {
  name: '${mlWorkspaceName}-AVD-Hostpool'
  scope: resourceGroup(rg.name) 
  params: {
    loadBalancerType: 'BreadthFirst'
    location: location
    name: '${mlWorkspaceName}-AVD-Hostpool'
    hostPoolType: 'Pooled'
    preferredAppGroupType: 'Desktop'     
  }  
}

module appGroup '../../Modules/Microsoft.DesktopVirtualization/applicationgroups.bicep' = {
  name: '${mlWorkspaceName}-AVD-AppGroup'
  scope: resourceGroup(rg.name)
  params: {
    applicationGroupType: 'Desktop'
    hostpoolResourceId: hostPool.outputs.id
    description: 'Desktop App Group'
    location: location
    name: '${mlWorkspaceName}-AVD-AppGroup'    
  }  
}

module avdWorkspace '../../Modules/Microsoft.DesktopVirtualization/workspaces.bicep' = {
  name: '${mlWorkspaceName}-AVD-Workspace'
  scope: resourceGroup(rg.name)
  params: {
    description: 'Access to private ML Workspace'
    location: location
    name: '${mlWorkspaceName}-AVD-Workspace'
    applicationGroupReferences: [
      appGroup.outputs.id
    ]     
  }   
}
