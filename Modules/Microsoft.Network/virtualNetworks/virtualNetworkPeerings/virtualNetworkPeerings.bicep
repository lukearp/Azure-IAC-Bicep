param peeringName string
param vnetName string
param remoteNetworkId string
param allowGatewayTransit bool
param useRemoteGateway bool
param allowForwardedTraffic bool
param allowVnetAccess bool

resource vnet 'Microsoft.Network/virtualNetworks@2021-08-01' existing = {
  name: vnetName 
}

resource peerRemoteGateway 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-08-01' = if(useRemoteGateway == true && allowGatewayTransit == false){
  name: peeringName
  parent: vnet
  properties: {
    allowForwardedTraffic: allowForwardedTraffic
    useRemoteGateways: useRemoteGateway
    allowVirtualNetworkAccess: allowVnetAccess
    remoteVirtualNetwork: {
      id: remoteNetworkId 
    }    
  } 
}

resource peerGatewayTransit 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-08-01' = if(allowGatewayTransit == true && useRemoteGateway == false){
  name: peeringName
  parent: vnet
  properties: {
    allowForwardedTraffic: allowForwardedTraffic
    allowGatewayTransit: allowGatewayTransit
    allowVirtualNetworkAccess: allowVnetAccess
    remoteVirtualNetwork: {
      id: remoteNetworkId 
    }    
  } 
}

resource peerNoGateway 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-08-01' = if(allowGatewayTransit == false && useRemoteGateway == false){
  name: peeringName
  parent: vnet
  properties: {
    allowForwardedTraffic: allowForwardedTraffic
    allowVirtualNetworkAccess: allowVnetAccess
    remoteVirtualNetwork: {
      id: remoteNetworkId 
    }    
  } 
}
