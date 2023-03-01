param name string
param location string
param tags object = {}
param gatewayIpAddress string
param configureBgp bool
param localAddressPrefixes array = []
param asn int = 0
param bgpPeeringAddress string = '1.1.1.1'

var localNetworkGatewayProperties = configureBgp == true ? {
  bgpSettings: {
    asn: asn
    bgpPeeringAddress: bgpPeeringAddress   
  }
  gatewayIpAddress: gatewayIpAddress 
  localNetworkAddressSpace: {
    addressPrefixes: localAddressPrefixes 
  }  
} : {
  gatewayIpAddress: gatewayIpAddress 
  localNetworkAddressSpace: {
    addressPrefixes: localAddressPrefixes 
  }  
}

resource localNetworkGateway 'Microsoft.Network/localNetworkGateways@2021-08-01' = {
  name: name
  location: location
  tags: tags
  properties: localNetworkGatewayProperties   
}

output id string = localNetworkGateway.id
