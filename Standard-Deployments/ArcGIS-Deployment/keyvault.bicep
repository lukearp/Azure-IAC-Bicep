param userObjectId string
param location string
param keyVaultName string
param deploymentPrefix string

var adminPassword = 'e${toLower(substring(replace(guid(userObjectId,resourceGroup().name,deploymentPrefix),'-',''),0,8))}${toUpper(substring(replace(guid(resourceGroup().name,userObjectId,deploymentPrefix),'-',''),0,8))}Z'
var servicePassword = adminPassword


resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(subscription().id,resourceGroup().name,userObjectId)
  scope: keyvault
  properties: { 
    roleDefinitionId: '/providers/Microsoft.Authorization/roleDefinitions/00482a5a-887f-4fb3-b363-3b7fe8e74483'
    principalId: userObjectId 
  }
}

resource keyvault 'Microsoft.KeyVault/vaults@2023-02-01' = {
  location: location
  name: keyVaultName
  properties: {
    enabledForTemplateDeployment: true
    sku: {
      family: 'A' 
      name: 'standard' 
    } 
    tenantId: tenant().tenantId  
    enableRbacAuthorization: true 
  }   
}

resource storageKey 'Microsoft.KeyVault/vaults/secrets@2023-02-01' = {
  name: 'esriStorage'
  parent: keyvault
  properties: {
    value: 'test'  
  }
  dependsOn:[
    roleAssignment
  ]   
}

resource adminPasswordKey 'Microsoft.KeyVault/vaults/secrets@2023-02-01' = {
  name: 'adminPassword'
  parent: keyvault
  properties: {
    value: adminPassword  
  }
  dependsOn:[
    roleAssignment
  ]   
}

resource servicePasswordKey 'Microsoft.KeyVault/vaults/secrets@2023-02-01' = {
  name: 'servicePassword'
  parent: keyvault
  properties: {
    value: servicePassword  
  }
  dependsOn:[
    roleAssignment
  ]   
}

output adminPasswordName string = adminPasswordKey.name
output servicePasswordName string = servicePasswordKey.name
output storageKeyName string = storageKey.name
output rootCertName string = 'ss-root'
output internalName string = 'internal-cert'
output externalName string = 'external-cert'
