param name string
param location string
@allowed([
  'BlobStorage'
  'BlockBlobStorage'
  'FileStorage'
  'Storage'
  'StorageV2'
])
param kind string
@allowed([
  'Premium_LRS'
  'Premium_ZRS'
  'Standard_GRS'
  'Standard_GZRS'
  'Standard_LRS'
  'Standard_RAGRS'
  'Standard_RAGZRS'
  'Standard_ZRS'
])
param sku string = 'Standard_LRS'
@allowed([
  'Cool'
  'Hot'
])
param accessTier string = 'Hot'
param enableDiagnostics bool = false
param eventHubAuthorizationRuleId string = ''
param eventHubName string = ''
param serviceBusRuleId string = ''
param storageAccountId string = ''
param workspaceId string = ''
param tags object = {}

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: name
  location: location
  kind: kind 
  sku: {
    name: sku
  } 
  properties: {
     accessTier: accessTier 
  }   
  tags: tags
}

var metrics = [
  {
    enabled: true
    category: 'Transaction'  
  }
]

module diagProperties '../../Microsoft.Insights/diagnosticsProperties.bicep' = {
  name: 'BuildDiagProperties'
  params: {
    metrics: metrics
    workspaceId: workspaceId  
  }  
}

resource diag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if(enableDiagnostics == true){
  name: name
  scope: storageAccount
  properties: diagProperties.outputs.properties  
}

output storageAccountId string = storageAccount.id
