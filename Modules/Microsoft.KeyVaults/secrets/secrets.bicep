param keyVaultName string
param secretName string
@secure()
param value string

resource key 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: keyVaultName
}

resource keyVaultSecret 'Microsoft.KeyVault/vaults/secrets@2023-02-01' = {
  name: secretName
  parent: key
  properties: {
    contentType: 'string'
    value: value   
  }   
}
