param name string
param remoteServiceResourceId string
param subnetResourceId string
param targetSubResource array = []
param location string

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2021-03-01' = {
  name: name
  location: location
  properties: {
    manualPrivateLinkServiceConnections: [
      {
        name: name
        properties: {
          privateLinkServiceId: remoteServiceResourceId 
          groupIds: targetSubResource          
        }  
      }
    ] 
    subnet: {
      id: subnetResourceId 
    } 
  }  
}
