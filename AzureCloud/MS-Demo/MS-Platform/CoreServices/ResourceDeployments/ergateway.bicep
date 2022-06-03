targetScope = 'subscription'
@secure()
param authorizationKey string

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
   name: 'core-vpn-networking-eastus-rg'
}

module erGateway '../../../../../Modules/Microsoft.Network/virtualNetworkGateways/virtualNetworkGateways.bicep' = {
  name: 'Adhoc-ER-Gateway'
  scope: resourceGroup(rg.name)
  params: {
    active_active: false
    asn: 65000
    gatewayName: 'Core-ER'
    gatewaySku: 'Standard'
    gatewayType: 'ExpressRoute'
    targetVnetId: resourceId(split(rg.id,'/')[2],rg.name,'Microsoft.Network/virtualNetworks','core-vpn-vnet-eastus')
    vpnType: 'RouteBased'
    location: 'eastus'
    tags: {
      Environment: 'Prod'
    }        
  }    
}

module erConnection '../../../../../Modules/Microsoft.Network/connections/connections.bicep' = {
  name: 'AVS-ER-Connection'
  scope: resourceGroup(rg.name)
  params: {
    connectionType: 'ExpressRoute'
    location: 'eastus'
    name: 'AVS-Connection'
    tags: {
      Environment: 'Prod'
    }
    virtualNetworkGateway1: erGateway.outputs.id
    authorizationKey: authorizationKey 
    erCircuitId: '/subscriptions/e2f192a7-f4e1-4289-b895-52a60dc29fb7/resourceGroups/tnt80-cust-p01-brazilsouth/providers/Microsoft.Network/expressRouteCircuits/tnt80-cust-p01-brazilsouth-er'       
  }   
}
