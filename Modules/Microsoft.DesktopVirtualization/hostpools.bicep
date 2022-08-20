param name string
param location string
@allowed([
  'Personal'
  'Pooled'
  'BYODesktop'
])
param hostPoolType string = 'Pooled'
@allowed([
  'Desktop'
  'None'
])
param preferredAppGroupType string = 'Desktop'
@allowed([
  'BreadthFirst'
  'DepthFirst'
  'Persistent'
])
param loadBalancerType string

resource hostpool 'Microsoft.DesktopVirtualization/hostPools@2022-04-01-preview' = {
  name: name
  location: location
  properties: {
    publicNetworkAccess: 'Enabled'
    hostPoolType: hostPoolType
    preferredAppGroupType: preferredAppGroupType
    loadBalancerType: loadBalancerType
  } 
}
