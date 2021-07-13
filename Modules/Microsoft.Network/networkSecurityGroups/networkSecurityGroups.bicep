param nsgs array
param location string = resourceGroup().location
param tags object = {}

resource nsg 'Microsoft.Network/networkSecurityGroups@2020-11-01' = [for securityGroup in nsgs: {
  name: securityGroup.name
  location: location
  properties: {
    securityRules: []
  } 
  tags: tags
}]

output nsgIds array = [for (securityGroup, i) in nsgs: {
  id: nsg[i].id
}]
