param name string
param remoteServiceResourceId string
param subnetResourceId string
param targetSubResource array = []
param requestMessage string = 'Needing Access'
param location string
param manual bool = false
param tags object = {}

var privateLinkServiceConnections = manual == false ? [
  {
    name: name
    properties: {
      privateLinkServiceId: remoteServiceResourceId
      groupIds: targetSubResource
      requestMessage: requestMessage
    }
  }
] : []

var manualPrivateLinkServiceConnections = manual == true ? [
  {
    name: name
    properties: {
      privateLinkServiceId: remoteServiceResourceId
      groupIds: targetSubResource
      requestMessage: requestMessage
    }
  }
] : []

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2021-03-01' = {
  name: name
  location: location
  properties: {
    privateLinkServiceConnections: privateLinkServiceConnections
    manualPrivateLinkServiceConnections: manualPrivateLinkServiceConnections
    subnet: {
      id: subnetResourceId
    }
  }
  tags: tags 
}

output networkInterfaces array = privateEndpoint.properties.networkInterfaces
output customerDnsConfigs array = privateEndpoint.properties.customDnsConfigs
