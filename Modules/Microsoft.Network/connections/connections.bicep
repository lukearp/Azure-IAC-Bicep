param name string
param location string
param tags object
@allowed([
  'IPsec'
  'ExpressRoute'
])
param connectionType string
param virtualNetworkGateway1 string
param localNetworkGateway2 string
@allowed([
  'IKEv1'
  'IKEv2'
])
param connectionProtocol string = 'IKEv2'
param enableBgp bool
param sharedKey string
param usePolicyBasedTrafficSelectors bool

resource connection 'Microsoft.Network/connections@2021-08-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    connectionType: connectionType
    virtualNetworkGateway1: {
      id: virtualNetworkGateway1
      properties: {}  
    }
    localNetworkGateway2: {
      id: localNetworkGateway2
      properties: {}
    }
    connectionMode: 'Default'
    connectionProtocol: connectionProtocol
    enableBgp: enableBgp
    sharedKey: sharedKey
    usePolicyBasedTrafficSelectors: usePolicyBasedTrafficSelectors         
  }    
}
