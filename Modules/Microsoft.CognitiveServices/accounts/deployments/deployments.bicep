param accountId string
param name string
@allowed([
  'Standard'
])
param sku string = 'Standard'
@allowed([
  'OpenAI'
])
param format string = 'OpenAI'
@allowed([
  'gpt-35-turbo'
])
param modelName string = 'gpt-35-turbo'
param capacity int = 15

resource account 'Microsoft.CognitiveServices/accounts@2023-10-01-preview' existing = {
  name: split(accountId,'/')[8]  
}

resource deployment 'Microsoft.CognitiveServices/accounts/deployments@2023-10-01-preview' = {
  name: name
  parent: account
  sku: {
    name: sku
    capacity: capacity
  }  
  properties: {
    versionUpgradeOption: 'OnceNewDefaultVersionAvailable'
    currentCapacity: capacity  
    model: {
      format: format
      name: modelName 
    }
    raiPolicyName: 'Microsoft.Default'
  } 
}
