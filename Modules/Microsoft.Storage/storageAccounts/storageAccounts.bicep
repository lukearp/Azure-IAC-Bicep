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
param enableHierarchicalNamespace bool = false
param enableDiagnostics bool = false
param disablePublicAccess bool = false
param supportsHttpsTrafficOnly bool = true
/*
param eventHubAuthorizationRuleId string = ''
param eventHubName string = ''
param serviceBusRuleId string = ''
param storageAccountId string = ''
*/
param workspaceId string = ''
param publicNetworkAccess bool = true
param storeKeysInKeyVault bool = false
param keyVaultName string = ''
param keyVaultRg string = ''
param keyVaultSubscription string = ''
param secretName string = ''
param generateSas bool = false
param expireInDays string = '1'
param date string = utcNow('u')
param tags object = {}

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: name
  location: location
  kind: kind 
  sku: {
    name: sku
  } 
  properties: {
     accessTier: accessTier 
     isHnsEnabled: enableHierarchicalNamespace 
     allowBlobPublicAccess: disablePublicAccess
     supportsHttpsTrafficOnly: supportsHttpsTrafficOnly 
     publicNetworkAccess: publicNetworkAccess == false ? 'Disabled' : 'Enabled' 
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

module secret1 '../../Microsoft.KeyVaults/secrets/secrets.bicep' = if(storeKeysInKeyVault == true){
  name: '${name}-key1' 
  scope: resourceGroup(keyVaultSubscription, keyVaultRg)
  params: {
    keyVaultName: keyVaultName
    secretName: secretName
    value: storageAccount.listKeys().keys[0].value   
  } 
}
var expire = dateTimeAdd(date,'P1D')
var sasToken = generateSas == true ? storageAccount.listAccountSas(storageAccount.apiVersion, {
  signedExpiry: expire
  signedPermission: 'r'
  signedStart: date
  signedServices: 'b'
  signedResourceTypes: 's'
  keyToSign: 'key1'
  signedProtocol: 'https'       
}).accountSasToken : ''

output storageAccountId string = storageAccount.id
output endpoints object = storageAccount.properties.primaryEndpoints
output sas string = sasToken
