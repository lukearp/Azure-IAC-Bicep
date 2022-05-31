targetScope = 'subscription'
param sharedKey string

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: 'core-hub-vnet-eastus'
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
    bgpPeeringAddress: '192.168.0.1'
    asn: 65550          
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
    virtualNetworkGateway1: resourceId('Microsoft.Network/virtualNetworkGateways', 'Core-VPN')        
  }   
}