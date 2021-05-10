param vnetName string = 'test'
param vnetAddressSpaces array = [
  '10.0.0.0/24'
]
param vnetDnsServers array = [
  '192.168.1.1'
  '192.168.1.2'
]
param vmSubnets array = [
  {
    name: 'mysub'
    addressPrefix: '10.0.0.0/27'
  }
  {
    name: 'mysub2'
    addressPrefix: '10.0.0.32/27'
  }
]

param serviceSubnets array = [
  {
    name: 'GatewaySubnet'
    addressPrefix: '10.0.0.224/27'
  }
]

param gatewayObject object = {
  gatewayName: 'myGateway'
  active_active: true
  asn: 64513
  vpnType:'RouteBased'
  gatewaySku: 'VpnGw1'
  gatewayType: 'Vpn'
}

var nsgArray = [for subnet in vmSubnets: {
  name: 'NSG_${subnet.name}'
}]

module nsg '../../../../Modules/Microsoft.Network/networkSecurityGroups/networkSecurityGroups.bicep' = {
   name: 'NSG_Deploy'
   params:{
     nsgs: nsgArray
   } 
}

var vnetSubnets = concat(vmSubnets,serviceSubnets)

module vnet '../../../../Modules/Microsoft.Network/virtualNetworks/virtualNetworks.bicep' = {
  name: 'VNET_Deploy'
  params:{
    vnetName: vnetName
    vnetAddressSpaces: vnetAddressSpaces
    vnetDnsServers: vnetDnsServers
    vnetSubnets: vnetSubnets  
    networkSecurityGroups: nsg.outputs.nsgIds
  } 
}

module gateway '../../../../Modules/Microsoft.Network/virtualNetworkGateways/virtualNetworkGateways.bicep' = if(gatewayObject != null) {
  name: 'GatewayDeploy'
  params:{
   gatewayName: gatewayObject.gatewayName
   active_active: gatewayObject.active_active
   asn: gatewayObject.asn
   targetVnetId: vnet.outputs.resourceId 
   vpnType:gatewayObject.vpnType
   gatewaySku: gatewayObject.gatewaySku
   gatewayType: gatewayObject.gatewayType             
  }
}
