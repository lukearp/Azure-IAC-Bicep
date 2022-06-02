param name string
param location string
param tags object = {}

resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2021-09-30-preview' = {
  location: location
  name: name
  tags : tags  
}

output clientId string = identity.properties.clientId
output principalId string = identity.properties.principalId
output resourceId string = identity.id
