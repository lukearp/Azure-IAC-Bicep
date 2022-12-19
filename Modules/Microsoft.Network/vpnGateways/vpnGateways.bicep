param name string
param location string
param hubId string
param internetRouting bool = false
param vpnGatewayScaleUnit int = 1
param configureBgp bool = false

/*
bgpSettings: {
       asn:
       bgpPeeringAddress:
       bgpPeeringAddresses:
       peerWeight: 
    }
*/

resource gateway 'Microsoft.Network/vpnGateways@2022-05-01' = {   
  name: name
  location: location
  properties: {     
    virtualHub: {
      id: hubId  
    }
    vpnGatewayScaleUnit: vpnGatewayScaleUnit
    isRoutingPreferenceInternet: internetRouting     
  } 
}

output vpnGatewayId string = gateway.id
