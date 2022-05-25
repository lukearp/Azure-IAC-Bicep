param name string
param vnetAddressSpace string
param dnsServers array = []
param disableBgpRoutePropagation bool
param location string
param nsgRules array
param routes array
param subnets array
param gateways array
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
  gateways: [
    {
      name: 'gatewayName'
      location: 'region'
      subnetId: 'subnetId'
      activeActive: 'bool'
      size: 'VpnGw1'
      generation: '1 or 2'
      type: 'VPN or ER'
    }
  ]
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

var subnetsConfig = [for (subnet,i) in subnets: union(subnetbase[i],subnetNsg[i],subnetRt[i])]

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
    subnets: subnetCreate 
}

resource vnet 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: name 
  location: location
  properties: vnetPropertiesBase
  tags: tags
}
//Basic Standard
resource publicIps 'Microsoft.Network/publicIPAddresses@2021-05-01' = [for pip in gateways: {
 name: '${pip.name}-pip'
 location: location
 sku: {
   name: contains(pip.size,'Az') ? 'Standard' : 'Basic'
   tier: 'Regional'  
 } 
 properties: {
   publicIPAllocationMethod: contains(pip.size,'Az') ? 'Static' : 'Dynamic'  
 } 
 tags: tags   
}]

resource vpnGateway 'Microsoft.Network/virtualNetworkGateways@2021-05-01' = [for (gateway,i) in gateways: if(toLower(gateway.type) == 'vpn' ) {
  name: gateway.name
  location: location
  properties: {
    gatewayType: gateway.type
    sku: {
      name: gateway.size
      tier: gateway.size 
    } 
    vpnType: 'RouteBased' 
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          subnet: {
            id: '${vnet.id}/subnets/GatewaySubnet'
          } 
          publicIPAddress: {
            id: publicIps[i].id 
          } 
        }  
      } 
    ]   
  } 
  tags: tags      
}]

resource erGateway 'Microsoft.Network/virtualNetworkGateways@2021-05-01' = [for (gateway,i) in gateways: if(toLower(gateway.type) != 'vpn' ) {
  name: gateway.name
  location: location
  properties: {
    gatewayType: gateway.type
    sku: {
      name: gateway.size
      tier: gateway.size 
    } 
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          subnet: {
            id: '${vnet.id}/subnets/GatewaySubnet'
          } 
          publicIPAddress: {
            id: publicIps[i].id 
          } 
        }  
      } 
    ]   
  } 
  tags: tags      
}]

output vnetId string = vnet.id
