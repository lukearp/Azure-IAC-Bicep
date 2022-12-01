param name string
param location string
@allowed([
  'Basic'
/*  'Free'
  'Premium'
  'Standard'*/
])
param tier string = 'Basic'
@allowed([
  'SystemAssigned'
  'None'
])
param identity string
param storageAccountId string
param keyVaultId string
param containerRegisteryId string
param applicationInsightsId string
param v1LegacyMode bool = false
@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccess string = 'Enabled'
param tags object = {}

resource ml 'Microsoft.MachineLearningServices/workspaces@2022-05-01' = {
  name: name
  sku: {
     name: tier
     tier: tier
  } 
  identity: {
    type: identity
  } 
  location: location
  properties: {
    friendlyName: name
    storageAccount: storageAccountId
    keyVault: keyVaultId
    containerRegistry: containerRegisteryId
    v1LegacyMode: v1LegacyMode 
    publicNetworkAccess: publicNetworkAccess 
    applicationInsights: applicationInsightsId 
  }  
  tags: tags  
}

output mlWorkspaceId string = ml.id
output principalId string = ml.identity.principalId
