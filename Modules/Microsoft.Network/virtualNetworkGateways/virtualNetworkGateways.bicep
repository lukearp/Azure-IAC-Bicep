param gatewayName string
param targetVnetId string
param active_active bool
param asn int = 65515
@allowed([
  'Vpn'
  'ExpressRoute'
])
param gatewayType string
@allowed([
  'Basic'
  'ErGw1AZ'
  'ErGw2AZ'
  'ErGw3AZ'
  'HighPerformance'
  'Standard'
  'UltraPerformance'
  'VpnGw1'
  'VpnGw1AZ'
  'VpnGw2'
  'VpnGw2AZ'
  'VpnGw3'
  'VpnGw3AZ'
  'VpnGw4'
  'VpnGw4AZ'
  'VpnGw5'
  'VpnGw5AZ'
])
param gatewaySku string
@allowed([
  'RouteBased'
  'PolicyBased'
])
param vpnType string
param location string = resourceGroup().location
param useExistingPublicIP bool = false
param publicIps array = []
param tags object = {}

var ipConfigs = active_active == true && toLower(gatewayType) == 'vpn' && useExistingPublicIP == false? [
  {
    name: 'ipconfig1'
    properties:{
      subnet:{
        id: '${targetVnetId}/subnets/GatewaySubnet' 
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
        id: '${targetVnetId}/subnets/GatewaySubnet' 
      }
      publicIPAddress:{
        id: '${resourceGroup().id}/providers/Microsoft.Network/publicIpAddresses/${gatewayName}2-pip'
      }
    } 
  }
] : active_active == true && toLower(gatewayType) == 'vpn' && useExistingPublicIP == true ? [
  {
    name: 'ipconfig1'
    properties:{
      subnet:{
        id: '${targetVnetId}/subnets/GatewaySubnet' 
      }
      publicIPAddress:{
        id: publicIps[0]
      }
    } 
  }
  {
    name: 'ipconfig2'
    properties:{
      subnet:{
        id: '${targetVnetId}/subnets/GatewaySubnet' 
      }
      publicIPAddress:{
        id: publicIps[1]
      }
    } 
  }
] : toLower(gatewayType) == 'vpn' && useExistingPublicIP == false ? [
  {
    name: 'ipconfig1'
    properties:{
      subnet:{
        id: '${targetVnetId}/subnets/GatewaySubnet' 
      }
      publicIPAddress:{
        id: '${resourceGroup().id}/providers/Microsoft.Network/publicIpAddresses/${gatewayName}1-pip'
      }
    } 
  } 
] : [
  {
    name: 'ipconfig1'
    properties:{
      subnet:{
        id: '${targetVnetId}/subnets/GatewaySubnet' 
      }
      publicIPAddress:{
        id: publicIps[0]
      }
    } 
  }
]

var gatewayProperties = toLower(gatewayType) == 'vpn' ? gatewaySku != 'Basic' ? {
  activeActive: active_active
  enableBgp: true 
  bgpSettings: {
    asn: asn
  }
  ipConfigurations: ipConfigs 
  gatewayType: gatewayType
  sku:{
     name: gatewaySku
     tier: gatewaySku 
  }
  vpnType: vpnType       
} : {
  activeActive: active_active
  ipConfigurations: ipConfigs 
  gatewayType: gatewayType
  sku:{
     name: gatewaySku
     tier: gatewaySku 
  }
  vpnType: vpnType       
} : {
  ipConfigurations: ipConfigs 
  gatewayType: gatewayType
  sku:{
     name: gatewaySku
     tier: gatewaySku 
  }
} 

var pipSku = active_active == true && contains(gatewaySku, 'AZ') ? 'Standard': 'Basic'
var pipAllocationMethod = active_active == true && contains(gatewaySku, 'AZ') ? 'Static' : 'Dynamic'

module pip '../publicIpAddresses/publicIpAddresses.bicep' = [for (ip, i) in ipConfigs : if(useExistingPublicIP == false ) {
  name: '${gatewayName}-pip-${i + 1}'
  params:{
    name: '${gatewayName}${i + 1}-pip'
    publicIpAddressVersion:'IPv4'
    publicIpAllocationMethod: pipAllocationMethod
    sku: pipSku
    tier: 'Regional' 
    tags: tags
    location: location 
  } 
}]

resource vnetGateway 'Microsoft.Network/virtualNetworkGateways@2020-11-01' = {
 name: gatewayName
 location: location
 properties: gatewayProperties 
 dependsOn: [
   pip
 ]
 tags: tags 
}

output id string = vnetGateway.id
