targetScope = 'subscription'
param location string
param NamePrefix string
param ipRules array
param DefaultNetworkAction string
param uniqueAssetName string

resource openAiGroup 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  location: location
  name: '${NamePrefix}-OpenAI-rg'   
}

module openAi '../../Modules/Microsoft.CognitiveServices/accounts/accounts.bicep' = {
  name: '${NamePrefix}-AI-WP-Deploy'
  scope: resourceGroup(openAiGroup.name)
  params: {
    name: '${NamePrefix}-AI-WP'
    location: location 
    ipRules: ipRules 
    networkDefaultAction: DefaultNetworkAction
  }
}

module deployment '../../Modules/Microsoft.CognitiveServices/accounts/deployments/deployments.bicep' = {
  name: '${NamePrefix}-AI-Deployment-Deploy'
  scope: resourceGroup(openAiGroup.name)
  params: {
    accountId: openAi.outputs.accountId
    name: '${NamePrefix}-GPT35-Deployment'  
  }
}

module openAiStorage '../../Modules/Microsoft.Storage/storageAccounts/storageAccounts.bicep' = {
  name: '${NamePrefix}-AI-Storage-Deploy'
  scope: resourceGroup(openAiGroup.name)
  params: {
    kind: 'StorageV2'
    location: location
    name: uniqueAssetName 
    ipRules: ipRules
    networkDefaultAction: DefaultNetworkAction 
    // TO DO Add ways to limit Access to Storage Account via source IPs 
  } 
}

module openAiStorageContainer '../../Modules/Microsoft.Storage/storageAccounts/containers/containers.bicep' = {
  name: '${NamePrefix}-AI-Storage-Container-Deploy'
  scope: resourceGroup(openAiGroup.name)
  params: {
     storageAccountName: uniqueAssetName
     containerName: '${toLower(NamePrefix)}data'
  } 
}
