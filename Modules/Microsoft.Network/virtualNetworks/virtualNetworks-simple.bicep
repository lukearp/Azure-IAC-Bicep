param name string
param location string
param addressSpacePrefixes array
param dnsServers array
param subnets array
param tags object = {}

resource vnet 'Microsoft.Network/virtualNetworks@2022-07-01' = {
  name: name
  tags: tags
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: addressSpacePrefixes
    }
    dhcpOptions: {
      dnsServers: dnsServers 
    }
    subnets: subnets 
  }    
}

output resourceId string = vnet.id
