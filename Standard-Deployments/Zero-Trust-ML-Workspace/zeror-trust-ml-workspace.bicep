targetScope = 'subscription'

param resourceGroupName string
param mlWorkspaceName string
param location string
param enableDiagnostics bool = false
param logAnalyticsResourceId string = ''
param tags object = {}

var suffix = substring(replace(subscription().subscriptionId,'-',''),0,15)

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
