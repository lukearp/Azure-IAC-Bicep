targetScope = 'subscription'
param sharedKey string
@secure()
param authorizationKey string

resource vpnRg 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: 'core-vpn-networking-eastus-rg'
}

resource erRg 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: 'core-er-networking-eastus-rg'
}

module localGateway '../../../../../Modules/Microsoft.Network/localNetworkGateways/localNetworkGateways.bicep' = {
  name: 'Home-LG-Deploy'
  scope: resourceGroup(vpnRg.name)
  params: {
    configureBgp: true
    gatewayIpAddress: '35.132.216.178'
    location: 'eastus'
    name: 'Home-Gateway'
    tags: {
      Environment: 'Prod'
    }
    localAddressPrefixes: []
    bgpPeeringAddress: '192.168.3.1'
    asn: 65525          
  }   
}

module connection '../../../../../Modules/Microsoft.Network/connections/connections.bicep' = {
  name: 'Home-VPN-Connection'
  scope: resourceGroup(vpnRg.name)
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
    virtualNetworkGateway1: resourceId('32eb88b4-4029-4094-85e3-ec8b7ce1fc00',vpnRg.name,'Microsoft.Network/virtualNetworkGateways', 'Core-VPN')        
  }   
}

module erConnection '../../../../../Modules/Microsoft.Network/connections/connections.bicep' = {
  name: 'AVS-ER-Connection'
  scope: resourceGroup(erRg.name)
  params: {
    connectionType: 'ExpressRoute'
    location: 'eastus'
    name: 'AVS-Connection'
    tags: {
      Environment: 'Prod'
    }
    virtualNetworkGateway1: resourceId('32eb88b4-4029-4094-85e3-ec8b7ce1fc00',erRg.name,'Microsoft.Network/virtualNetworkGateways', 'Core-ER')
    authorizationKey: authorizationKey 
    erCircuitId: '/subscriptions/e2f192a7-f4e1-4289-b895-52a60dc29fb7/resourceGroups/tnt80-cust-p01-brazilsouth/providers/Microsoft.Network/expressRouteCircuits/tnt80-cust-p01-brazilsouth-er'       
  }   
}
