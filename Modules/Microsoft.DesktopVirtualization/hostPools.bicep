param name string
param location string
@allowed([
  'Personal'
  'Pooled'
])
param hostPoolType string = 'Pooled'
@allowed([
  'DepthFirst'
  'BreadthFirst'
  'Persistent'
])
param loadBalancerType string = 'BreadthFirst'
param description string
param friendlyName string

resource hostPool 'Microsoft.DesktopVirtualization/hostPools@2022-02-10-preview' = {
  name: name
  location: location
  properties: {
    hostPoolType: hostPoolType
    loadBalancerType: loadBalancerType
    agentUpdate: {
      useSessionHostLocalTime: true
      maintenanceWindows: [
        {
          dayOfWeek: 'Sunday'
          hour: 2   
        } 
      ]
      type: 'Default' 
    }
    description: description
    friendlyName: friendlyName 
    preferredAppGroupType: 'Desktop'      
  }  
}
