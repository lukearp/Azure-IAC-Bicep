param name string
param hubName string
param vnetId string
param associatedRouteTableId string
param propigatedRouteTableIds array = []
param routeTableLabels array = []
param staticRoutes array = []

resource hub 'Microsoft.Network/virtualHubs@2022-05-01' existing = {
  name: hubName  
}

resource vnet 'Microsoft.Network/virtualHubs/hubVirtualNetworkConnections@2022-05-01' = {
  name: name
  parent: hub
  properties: {
    remoteVirtualNetwork: {
      id: vnetId 
    } 
    routingConfiguration: {
      associatedRouteTable: {
        id: associatedRouteTableId        
      }
      propagatedRouteTables: {
        ids: propigatedRouteTableIds
        labels: routeTableLabels  
      } 
      vnetRoutes: {
        staticRoutesConfig: {
          vnetLocalRouteOverrideCriteria: 'Contains'  
        }
        staticRoutes: staticRoutes 
      }  
    } 
  }   
}
