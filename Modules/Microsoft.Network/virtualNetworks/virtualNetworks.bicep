param vnetName string
param vnetAddressSpaces array
param vnetDnsServers array
param vnetSubnets array
param networkSecurityGroups array
param location string = resourceGroup().location
param tags object = {}

var subnets = [for (subnet,i) in vnetSubnets: contains(networkSecurityGroups, subnet.name) ? {
  name: subnet.name
  properties:{
    addressPrefix: subnet.addressPrefix         
    networkSecurityGroup: {
      id: networkSecurityGroups[i] 
    }
  }
}:{
  name: subnet.name
  properties:{
    addressPrefix: subnet.addressPrefix
  }
}]

resource vnet 'Microsoft.Network/virtualNetworks@2020-11-01' = {
  name: vnetName
  location: location
  properties:{
    addressSpace: {
      addressPrefixes: vnetAddressSpaces
    }
    dhcpOptions:{
      dnsServers: vnetDnsServers
    }
    subnets: subnets
  }
  tags: tags
}

output resourceId string = vnet.id
