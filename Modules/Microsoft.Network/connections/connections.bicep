param name string
param location string
param tags object
@allowed([
  'IPsec'
  'ExpressRoute'
])
param connectionType string
param virtualNetworkGateway1 string
param localNetworkGateway2 string = ''
@allowed([
  'IKEv1'
  'IKEv2'
])
param connectionProtocol string = 'IKEv2'
param enableBgp bool = true
param sharedKey string = ''
param usePolicyBasedTrafficSelectors bool = false
param authorizationKey string = ''
param erCircuitId string = ''

var properties = connectionType == 'IPsec' ? {
  connectionType: connectionType
  virtualNetworkGateway1: {
    id: virtualNetworkGateway1
    properties: reference(virtualNetworkGateway1, '2020-11-01', 'FULL').properties  
  }
  localNetworkGateway2: {
    id: localNetworkGateway2
    properties: reference(localNetworkGateway2, '2021-08-01', 'FULL').properties  
  }
  connectionMode: 'Default'
  connectionProtocol: connectionProtocol
  enableBgp: enableBgp
  sharedKey: sharedKey
  usePolicyBasedTrafficSelectors: usePolicyBasedTrafficSelectors         
} : {
  connectionType: connectionType
  virtualNetworkGateway1: {
    id: virtualNetworkGateway1
    properties: reference(virtualNetworkGateway1, '2020-11-01', 'FULL').properties  
  }
  authorizationKey: authorizationKey
  peer: {
    id: erCircuitId 
  }         
}

resource connection 'Microsoft.Network/connections@2021-08-01' = {
  name: name
  location: location
  tags: tags
  properties: properties   
}
