targetScope = 'subscription'
param location string
param name string
param resourceGroupName string
param privateLinkSubnetId string
param tags object = {}

resource rg 'Microsoft.Resources/resourceGroups@2019-05-01' = {
  name: resourceGroupName
  location: location
}

var storageName = 'dl${substring(replace(guid('${name}-${location}-${resourceGroupName}-${subscription().id}'),'-',''),0,15)}'
module storageAccount '../../Modules/Microsoft.Storage/storageAccounts/storageAccounts.bicep' = {
  name: 'StorageAccount-Deploy'
  scope: resourceGroup(rg.name)
  params: {
    kind: 'StorageV2'
    location: location
    name: storageName
    disablePubliAccess: true
    enableHierarchicalNamespace: true
    sku: 'Standard_LRS'
    supportsHttpsTrafficOnly: true
    publicNetworkAccess: false  
    tags: tags        
  }  
}

module synapse '../../Modules/Microsoft.Synapse/workspace.bicep' = {
  name: 'Synapse-Deploy'
  scope: resourceGroup(rg.name)
  params: {
    location: location
    name: name
    tags: tags
    storageDfsEndpoint: storageAccount.outputs.endpoints.dfs
    strorageResourceId: storageAccount.outputs.storageAccountId  
    createPrivateEndpointForStorage: true
  }  
}

module privateLinkBlob '../../Modules/Microsoft.Network/privateEndpoints/privateEndpoints.bicep' = {
  name: 'DL-PL-Blob-Deploy'
  scope: resourceGroup(rg.name)
  params: {
    location: location
    name: '${split(storageAccount.outputs.storageAccountId,'/')[8]}-blob-pl'
    remoteServiceResourceId: storageAccount.outputs.storageAccountId
    subnetResourceId: privateLinkSubnetId
    targetSubResource: [
      'blob'
    ]
    tags: tags    
  }   
}

module privateLinkDfs '../../Modules/Microsoft.Network/privateEndpoints/privateEndpoints.bicep' = {
  name: 'DL-PL-DFS-Deploy'
  scope: resourceGroup(rg.name)
  params: {
    location: location
    name: '${split(storageAccount.outputs.storageAccountId,'/')[8]}-dfs-pl'
    remoteServiceResourceId: storageAccount.outputs.storageAccountId
    subnetResourceId: privateLinkSubnetId
    targetSubResource: [
      'dfs'
    ]  
    tags: tags      
  }   
}

module privateLinkSynapse '../../Modules/Microsoft.Network/privateEndpoints/privateEndpoints.bicep' = {
  name: 'Synapse-PL-Deploy'
  scope: resourceGroup(rg.name)
  params: {
    location: location
    name: '${name}-pl'
    remoteServiceResourceId: synapse.outputs.synapsId
    subnetResourceId: privateLinkSubnetId
    targetSubResource: [
      'Sql'
    ] 
    tags: tags  
  } 
}
