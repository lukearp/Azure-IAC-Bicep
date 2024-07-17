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
@allowed([
  'Default'
  'FeatureStore'
  'Hub'
  'Project'
])
param kind string = 'Default'
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
param ipRules array = []
param tags object = {}

resource ml 'Microsoft.MachineLearningServices/workspaces@2024-01-01-preview' = {
  name: name
  sku: {
     name: tier
     tier: tier
  } 
  identity: {
    type: identity
  } 
  kind: kind 
  location: location
  properties: {
    friendlyName: name
    storageAccount: storageAccountId
    keyVault: keyVaultId
    containerRegistry: containerRegisteryId
    v1LegacyMode: v1LegacyMode 
    publicNetworkAccess: publicNetworkAccess 
    applicationInsights: applicationInsightsId  
    ipAllowlist: ipRules
  }  
  tags: tags  
}

output mlWorkspaceId string = ml.id
output principalId string = ml.identity.principalId
