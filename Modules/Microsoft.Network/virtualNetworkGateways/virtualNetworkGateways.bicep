param gatewayName string
param targetVnetName string
param targetVnetRg string
param active_active bool
param asn int
param location string = resourceGroup().location

var ipConfigs = active_active == true ? [
  {
    name: 'ipconfig1'
    properties:{
      subnet:{
        id: '${subscription().id}/resourceGroups/${targetVnetRg}/providers/Microsoft.Network/virtualNetworks/${targetVnetName}/subnets/GatewaySubnet' 
      }
      publicIPAddress:{
        id: '${resourceGroup().id}/providers/Microsoft.Network/publicIpAddresses/${gatewayName}1-pip'
      }
    } 
  }
  {
    name: 'ipconfig2'
    properties:{
      subnet:{
        id: '${subscription().id}/resourceGroups/${targetVnetRg}/providers/Microsoft.Network/virtualNetworks/${targetVnetName}/subnets/GatewaySubnet' 
      }
      publicIPAddress:{
        id: '${resourceGroup().id}/providers/Microsoft.Network/publicIpAddresses/${gatewayName}2-pip'
      }
    } 
  }
] : [
  {
    name: 'ipconfig1'
    properties:{
      subnet:{
        id: '${subscription().id}/resourceGroups/${targetVnetRg}/providers/Microsoft.Network/virtualNetworks/${targetVnetName}/subnets/GatewaySubnet' 
      }
      publicIPAddress:{
        id: '${resourceGroup().id}/providers/Microsoft.Network/publicIpAddresses/${gatewayName}1-pip'
      }
    } 
  }
]

var pipSku = active_active == true ? 'Standard': 'Basic'
var pipAllocationMethod = active_active == true ? 'Static' : 'Dynamic'

module pip '../publicIpAddresses/publicIpAddresses.bicep' = [for (ip, i) in ipConfigs :{
  name: 'pip-${i + 1}'
  params:{
    name: '${gatewayName}${i + 1}-pip'
    publicIpAddressVersion:'IPv4'
    publicIpAllocationMethod: pipAllocationMethod
    sku: pipSku
    tier: 'Regional'  
  } 
}]

resource vnetGateway 'Microsoft.Network/virtualNetworkGateways@2020-11-01' = {
 name: gatewayName
 location: location
 properties:{
   activeActive: active_active
   enableBgp: true 
   bgpSettings: {
     asn: asn
   }
   ipConfigurations: ipConfigs 
 } 
}
