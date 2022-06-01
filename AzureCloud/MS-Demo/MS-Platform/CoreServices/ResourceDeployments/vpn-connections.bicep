targetScope = 'subscription'
param sharedKey string

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: 'core-hub-networking-eastus-rg'
}

module localGateway '../../../../../Modules/Microsoft.Network/localNetworkGateways/localNetworkGateways.bicep' = {
  name: 'Home-LG-Deploy'
  scope: resourceGroup(rg.name)
  params: {
    configureBgp: true
    gatewayIpAddress: '35.132.216.178'
    location: 'eastus'
    name: 'Home-Gateway'
    tags: {
      Environment: 'Prod'
    }
    localAddressPrefixes: []
    bgpPeeringAddress: '192.168.1.1'
    asn: 65525          
  }   
}

module connection '../../../../../Modules/Microsoft.Network/connections/connections.bicep' = {
  name: 'Home-VPN-Connection'
  scope: resourceGroup(rg.name)
  params: {
    connectionType: 'IPsec'
    enableBgp: true
    localNetworkGateway2: localGateway.outputs.id
    location: 'eastus'
    name: 'To-Home'
    sharedKey: sharedKey
    tags: {
      Environment: 'Prod'
    } 
    usePolicyBasedTrafficSelectors: false
    connectionProtocol: 'IKEv2'
    virtualNetworkGateway1: resourceId('32eb88b4-4029-4094-85e3-ec8b7ce1fc00',rg.name,'Microsoft.Network/virtualNetworkGateways', 'Core-VPN')        
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
    virtualNetworkGateway1: resourceId('32eb88b4-4029-4094-85e3-ec8b7ce1fc00',rg.name,'Microsoft.Network/virtualNetworkGateways', 'Core-ER')
    authorizationKey: 'a922d45f-4c11-4f36-bf15-b8a90b43ba51' 
    erCircuitId: '/subscriptions/e2f192a7-f4e1-4289-b895-52a60dc29fb7/resourceGroups/tnt80-cust-p01-brazilsouth/providers/Microsoft.Network/expressRouteCircuits/tnt80-cust-p01-brazilsouth-er'       
  }   
}
