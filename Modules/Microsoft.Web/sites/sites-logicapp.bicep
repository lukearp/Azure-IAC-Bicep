param name string
param location string
param appServicePlanId string
param logicAppVNETSubnetId string = ''
param storageAccountConnectionString string
@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccessEnabled string = 'Enabled'
param tags object = {}

var properties = logicAppVNETSubnetId != '' ? {
  serverFarmId: appServicePlanId
  siteConfig: {
    appSettings: [
      {
        name: 'FUNCTIONS_EXTENSION_VERSION'
        value: '~4'
      }
      {
        name: 'FUNCTIONS_WORKER_RUNTIME'
        value: 'node'
      }
      {
        name: 'WEBSITE_NODE_DEFAULT_VERSION'
        value: '~14'
      }
      {
        name: 'AzureWebJobsStorage'
        value: storageAccountConnectionString
      }
      {
        name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
        value: storageAccountConnectionString
      }
      {
        name: 'WEBSITE_CONTENTSHARE'
        value: '${toLower(name)}88ba'
      }
      {
        name: 'AzureFunctionsJobHost__extensionBundle__id'
        value: 'Microsoft.Azure.Functions.ExtensionBundle.Workflows'
      }
      {
        name: 'AzureFunctionsJobHost__extensionBundle__version'
        value: '[1.*, 2.0.0)'
      }
      {
        name: 'APP_KIND'
        value: 'workflowApp'
      }
    ]  
  }
  virtualNetworkSubnetId: logicAppVNETSubnetId
  publicNetworkAccess: publicNetworkAccessEnabled
} : {
  serverFarmId: appServicePlanId
  siteConfig: {
    appSettings: [
      {
        name: 'FUNCTIONS_EXTENSION_VERSION'
        value: '~4'
      }
      {
        name: 'FUNCTIONS_WORKER_RUNTIME'
        value: 'node'
      }
      {
        name: 'WEBSITE_NODE_DEFAULT_VERSION'
        value: '~14'
      }
      {
        name: 'AzureWebJobsStorage'
        value: storageAccountConnectionString
      }
      {
        name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
        value: storageAccountConnectionString
      }
      {
        name: 'WEBSITE_CONTENTSHARE'
        value: '${toLower(name)}88ba'
      }
      {
        name: 'AzureFunctionsJobHost__extensionBundle__id'
        value: 'Microsoft.Azure.Functions.ExtensionBundle.Workflows'
      }
      {
        name: 'AzureFunctionsJobHost__extensionBundle__version'
        value: '[1.*, 2.0.0)'
      }
      {
        name: 'APP_KIND'
        value: 'workflowApp'
      }
    ]  
  }
  publicNetworkAccess: publicNetworkAccessEnabled 
} 

resource logicApp 'Microsoft.Web/sites@2022-03-01' = {
  location: location
  name: name
  kind: 'functionapp,workflowapp' 
  identity: {
    type: 'SystemAssigned' 
  }
  properties: properties
  tags: tags   
}

output resourceId string = logicApp.id
