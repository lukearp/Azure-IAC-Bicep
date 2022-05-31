param name string
param location string
param tags object
@allowed([
  'standard'
  'premium'
])
param sku string
param enableRbacAuthorization bool = true
param enabledForDeployment bool = false
param enabledForDiskEncryption bool = false
param enabledForTemplateDeployment bool = false
param enablePurgeProtection bool = false
param enableSoftDelete bool = false
param accessPolicies array = []
param networkAcls object = {}

resource keyvault 'Microsoft.KeyVault/vaults@2021-11-01-preview' = {
  name: name
  location: location
  tags: tags
  properties: {
    sku: {
      family: 'A'
      name: sku  
    }
    tenantId: tenant().tenantId
    enableRbacAuthorization: enableRbacAuthorization
    enabledForDeployment: enabledForDeployment
    enabledForDiskEncryption: enabledForDiskEncryption
    enabledForTemplateDeployment: enabledForTemplateDeployment
    enablePurgeProtection: enablePurgeProtection
    enableSoftDelete: enableSoftDelete
    accessPolicies: accessPolicies
    createMode: 'default'
    networkAcls: networkAcls                
  }  
}
