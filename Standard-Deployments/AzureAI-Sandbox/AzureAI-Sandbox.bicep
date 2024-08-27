targetScope = 'subscription'
param NamePrefix string = 'BAC'
param deployVnet bool = false
param useExistingVnet bool = false
param sampleDeploy bool = false
param deployOpenAI bool = false
param SubscriptionContributors array = []
@allowed([
  'User'
  'Group'
])
param principalType string = 'User'
param NetworkAddressPrefix string = '192.168.0.0/22'
param allowedSources array = []
@allowed([
  'basic'
])
param AISearchSku string = 'basic'
param location string = 'eastus'

// TO DO - Write Deployment Script to Query Object ID's of UPNs provided by SubscriptionContributors Array
// TO DO (maybe) - Register all Resource Providers on Subscription

resource rbacAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for contributor in SubscriptionContributors: {
  name: guid(contributor)
  properties: {
    principalType: principalType  
    principalId: contributor
    roleDefinitionId: '/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c'    
  }  
}]

module networking 'network-resources.bicep' = if(deployVnet == true) {
  name: '${NamePrefix}-Networking-Resources'
  params: {
    NamePrefix: NamePrefix
    location: location
    NetworkAddressPrefix: NetworkAddressPrefix  
  }
}

var ipRules = [for ip in allowedSources: {
  value: ip
}]

var DefaultNetworkAction = length(allowedSources) == 0 ? 'Allow' : 'Deny'

var suffix = replace(guid('${NamePrefix}-AI-Storage-Deploy',subscription().id),'-','')

var uniqueAssetName = substring('${toLower(NamePrefix)}ai${suffix}',0,23)

module openAI 'openAI-resources.bicep' = if(deployOpenAI == true){
  name: '${NamePrefix}-OpenAI-Resources'
  params: {
    NamePrefix: NamePrefix
    DefaultNetworkAction: DefaultNetworkAction
    ipRules: ipRules
    location: location
    uniqueAssetName: uniqueAssetName    
  }
}

resource aiStudioRg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  location: location
  name: '${NamePrefix}-AIStudio-rg' 
}

var uniqueAiStudioAssetName = substring('${toLower(NamePrefix)}ais${suffix}',0,23)

module aiStudioStorage '../../Modules/Microsoft.Storage/storageAccounts/storageAccounts.bicep' = {
  name: '${NamePrefix}-AIStudio-Storage-Deploy'
  scope: resourceGroup(aiStudioRg.name)
  params: {
    kind: 'StorageV2'
    location: location
    name: uniqueAiStudioAssetName 
    ipRules: ipRules
    networkDefaultAction: DefaultNetworkAction 
    // TO DO Add ways to limit Access to Storage Account via source IPs 
  } 
}

module search '../../Modules/Microsoft.Search/searchServices.bicep' = {
  name: '${NamePrefix}-AI-Search-Deploy'
  scope: resourceGroup(aiStudioRg.name)
  params: {
    location: location
    name: uniqueAssetName 
    sku: AISearchSku
    ipRules: ipRules 
  } 
}

resource searchRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(search.name)
  properties: {
    principalId: search.outputs.identity
    roleDefinitionId: '/providers/Microsoft.Authorization/roleDefinitions/2a2b9908-6ea1-4ae2-8e65-a410df84e7d1'  
  } 
}

/*resource mlGroup 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: '${NamePrefix}-ML-rg'
  location: location
  properties: {

  } 
}*/

module keyvault '../../Modules/Microsoft.KeyVaults/vaults.bicep' = {
  name: '${NamePrefix}-ML-KeyVault'
  scope: resourceGroup(aiStudioRg.name)
  params: {
    location: location
    name: substring('${toLower(NamePrefix)}kv${suffix}',0,23) 
    enableSoftDelete: true
    ipRules: ipRules
    networkDefaultAction: DefaultNetworkAction      
  }  
}

module acr '../../Modules/Microsoft.ContainerRegistry/registries.bicep' = {
  name: '${NamePrefix}-ML-ContainerRegistry'
  scope: resourceGroup(aiStudioRg.name) 
  params: {
    name: substring('${toLower(NamePrefix)}acr${suffix}',0,23)
    location: location
    sku: 'Premium' 
    networkDefaultAction: DefaultNetworkAction
    ipRules: ipRules    
  } 
}

module appInsights '../../Modules/Microsoft.Insights/components.bicep' = {
  name: '${NamePrefix}-ML-AppInsights' 
  scope: resourceGroup(aiStudioRg.name)
  params: {
    name: substring('${toLower(NamePrefix)}ap${suffix}',0,23)
    location: location
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
    tags: {}    
  }
}

module mlworkspace '../../Modules/Microsoft.MachineLearningServices/workspaces.bicep' = {
  name: '${NamePrefix}-ML-Deployment'
  scope: resourceGroup(aiStudioRg.name)
  params: {
    containerRegisteryId: acr.outputs.acrId
    identity: 'SystemAssigned'
    keyVaultId: keyvault.outputs.keyVaultId
    location: location
    name: '${NamePrefix}-ML-WP'
    storageAccountId: aiStudioStorage.outputs.storageAccountId
    publicNetworkAccess: 'Enabled'
    tier: 'Basic'
    v1LegacyMode: false
    applicationInsightsId: appInsights.outputs.appInsightId
    ipRules: allowedSources              
  }  
}

module aiStudio '../../Modules/Microsoft.MachineLearningServices/workspaces.bicep' = {
  name: '${NamePrefix}-AI-Studio-Deployment'
  scope: resourceGroup(aiStudioRg.name)
  params: {
    containerRegisteryId: acr.outputs.acrId
    identity: 'SystemAssigned'
    keyVaultId: keyvault.outputs.keyVaultId
    location: location
    name: '${NamePrefix}-AI-Studio'
    storageAccountId: aiStudioStorage.outputs.storageAccountId
    publicNetworkAccess: 'Enabled'
    tier: 'Basic'
    v1LegacyMode: false
    applicationInsightsId: appInsights.outputs.appInsightId
    ipRules: allowedSources  
    kind: 'Hub'            
  }  
}

module sample 'sample.bicep' = if(sampleDeploy == true) {
  name: '${NamePrefix}-AI-Sample-Deployment'
  scope: resourceGroup(aiStudioRg.name)
  params: {
    aiStudioResourceId: aiStudio.outputs.mlWorkspaceId
    location: location
    namePrefix: NamePrefix     
  }
}
