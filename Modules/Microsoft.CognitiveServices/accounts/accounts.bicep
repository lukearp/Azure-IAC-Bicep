param name string
param location string = resourceGroup().location
@allowed([
  'OpenAI'
])
param kind string = 'OpenAI'
@allowed([
  'S0'
])
param sku string = 'S0'
@allowed([
  'Enabled'
  'Disabled'
])
param publicAccess string = 'Enabled'
@allowed([
  'Allow'
  'Deny'
])
param networkDefaultAction string = 'Allow'
param virtualNetworkRules array = []
param ipRules array = []

resource account 'Microsoft.CognitiveServices/accounts@2023-10-01-preview' = {
  name: name
  sku: {
    name: sku 
  } 
  kind: kind
  location: location
  properties: {
    customSubDomainName: name
    networkAcls: {
      defaultAction: networkDefaultAction
      virtualNetworkRules: virtualNetworkRules
      ipRules: ipRules
    }
    publicNetworkAccess: publicAccess
  }
}

output accountId string = account.id
