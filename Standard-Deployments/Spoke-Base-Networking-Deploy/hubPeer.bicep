param hubVnetId string
param spokeVnetId string

var hubName = split(hubVnetId,'/')[8]
var spokeName = split(spokeVnetId,'/')[8]
resource vnet 'Microsoft.Network/virtualNetworks@2021-02-01' existing = {
  name: hubName
}

resource hubPeer 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-02-01' = {
  name: 'To-${spokeName}' 
  parent: vnet
  properties: {
    allowForwardedTraffic: true
    allowGatewayTransit: true
    allowVirtualNetworkAccess: true
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: spokeVnetId
    } 
  }
}
