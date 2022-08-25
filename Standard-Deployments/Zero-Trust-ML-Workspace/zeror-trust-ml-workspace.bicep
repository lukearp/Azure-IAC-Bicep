targetScope = 'subscription'

param resourceGroupName string
param mlWorkspaceName string
param location string
param tags object = {}

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}
module storage '../../Modules./Microsoft.Storage/storageAccounts/storageAccounts.bicep' = {
   name: '${mlWorkspaceName}-StorageDeployment'
   scope: resourceGroup(rg.name)
   params: {
    kind: 'StorageV2'
    location: location
    accessTier: 'Hot'
    sku: 'Standard_LRS'
    name: 'ml${substring(replace(subscription().subscriptionId,'-',''),0,15)}'    
   } 
}
