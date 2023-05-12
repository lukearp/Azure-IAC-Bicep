param name string
param vnetAddressSpace string
param dnsServers array = []
param disableBgpRoutePropagation bool
param location string
param nsgRules array
param routes array
param subnets array
param tags object = {}

/*
virtualNetworks Object = 
{
  name: 'vnetName'
  subId: 'subid'
  vnetAddressSpace: '10.0.0.0/22'
  dnsServers: []
  type: 'Hub or Spoke'
  location: 'azure Region'
  resourceGroupName: 'rgName'
  nsgRules: []
  routes: []
  disableBgpRoutePropagation: 'bool'
  subnets: [
    {
      name: 'subname'
      addressPrefix: '10.0.0.0/24'
      nsg: 'bool'
      routeTable: 'bool'
    }
  ]
}*/

resource nsg 'Microsoft.Network/networkSecurityGroups@2021-05-01' = {
  name: '${name}-${location}-nsg'
  location: location
  properties: {
    securityRules: nsgRules 
  }
  tags: tags 
}

resource rt 'Microsoft.Network/routeTables@2021-05-01' = {
  name: '${name}-${location}-rt'
  location: location
  properties: {
    disableBgpRoutePropagation: disableBgpRoutePropagation
    routes: routes 
  }
  tags: tags  
}
var subnetbase = [for subnet in subnets: {
  addressPrefix: subnet.addressPrefix
}]

var subnetNsg = [for subnet in subnets: subnet.nsg == true ? {
  networkSecurityGroup: {
    id: nsg.id
  }
}: {}]

var subnetRt = [for subnet in subnets: subnet.routeTable == true ? {
  routeTable: {
    id: rt.id
  }
}: {}]

var subnetsConfig = [for (subnet,i) in subnets : union(subnetbase[i],subnetNsg[i],subnetRt[i]) ]

var subnetCreate = [for (subnet,i) in subnets: {
  name: subnet.name
  properties: subnetsConfig[i]   
}]

var vnetPropertiesBase = {
    addressSpace: {
      addressPrefixes: [
        vnetAddressSpace
      ] 
    }
    dhcpOptions: {
      dnsServers: dnsServers 
    }
}

resource vnet 'Microsoft.Network/virtualNetworks@2022-11-01' = {
   name: name 
   location: location
   properties: vnetPropertiesBase
   tags: tags
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2022-11-01' = [for subnet in subnetCreate: {
  name: subnet.name
  parent: vnet
  properties: subnet.properties
}]

output vnetId string = vnet.id
