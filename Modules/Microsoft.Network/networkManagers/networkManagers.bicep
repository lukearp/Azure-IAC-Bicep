param name string
param location string
param tags object
param description string
param managementGroups array
param subscriptions array

resource networkManager 'Microsoft.Network/networkManagers@2022-02-01-preview' = {
  name: name
  location: location
  tags: tags
  properties: {
    description: description
    networkManagerScopeAccesses: [
      'Connectivity'
      'SecurityAdmin'
    ]
    networkManagerScopes: {
      managementGroups: managementGroups
      subscriptions: subscriptions
    }
  }
}
