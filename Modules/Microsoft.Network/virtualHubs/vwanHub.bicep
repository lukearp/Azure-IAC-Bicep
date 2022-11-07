param name string
param location string
param addressSpace string
param virtualWanId string
@allowed([
  'Basic'
  'Standard'
])
param sku string = 'Standard'
param virtualRouterScale int = 2
@allowed([
  'ASPath'
  'ExpressRoute'
  'VpnGateway'
])
param hubRoutingPreference string = 'ASPath'
param tags object = {}

resource hub 'Microsoft.Network/virtualHubs@2022-05-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    virtualWan: {
      id: virtualWanId
    }
    addressPrefix: addressSpace
    sku: sku
    virtualRouterAutoScaleConfiguration: {
      minCapacity: virtualRouterScale 
    }
    hubRoutingPreference: hubRoutingPreference
  } 
}

output hubId string = hub.id
