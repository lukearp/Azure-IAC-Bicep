param name string
param profileName string
param target string
param priority int
param hostheader string

resource trafficManagerProfile 'Microsoft.Network/trafficmanagerprofiles@2022-04-01' existing = {
  name: profileName 
}

resource trafficManagerEndpoint 'Microsoft.Network/trafficmanagerprofiles/ExternalEndpoints@2022-04-01' = { 
  parent: trafficManagerProfile
  name: name
  properties: {
    target: target
    priority: priority 
    customHeaders: [
      {
        name: 'host'
        value: hostheader 
      }
    ]  
  }  
}
