param name string
param hubName string
param labels array = []
param routes array = []

resource hub 'Microsoft.Network/virtualHubs@2022-05-01' existing = {
  name: hubName
}

/*
CIDR, ResourceId, Service
[
  {
        destinations: [
           
        ]
        destinationType: 
        nextHopType:
        name:
        nextHop:        
      }
]
*/

resource routeTable 'Microsoft.Network/virtualHubs/hubRouteTables@2022-05-01' = {
  name: name
  parent: hub
  properties: {
    labels: labels
    routes: routes    
  }   
}

output routeTableId string = routeTable.id
