param name string
param properties object
param location string
param tags object

resource updateDns 'Microsoft.Network/virtualNetworks@2021-08-01' = {
  name: name
  location: location
  tags: tags
  properties: properties    
}
