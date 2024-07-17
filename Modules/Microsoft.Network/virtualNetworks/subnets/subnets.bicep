param vnetname string
param subnetName string
param addressPrefix string
param nsgName string = ''
param routeTableName string = ''
param serviceEndpoints array = []
param subnetDelegation array = []

/*
serviceEndpoint object reference
{
  locations: [
           
  ] 
  service:  
}
*/
resource vnet 'Microsoft.Network/virtualNetworks@2021-08-01' existing = {
  name: vnetname
}

var properties = nsgName == '' && routeTableName == '' ? {
  addressPrefix: addressPrefix
  serviceEndpoints: serviceEndpoints
} : nsgName == '' && routeTableName != '' ? {
  addressPrefix: addressPrefix
  routeTable: {
    id: resourceId('Microsoft.Network/routeTables', routeTableName)
  }
  serviceEndpoints: serviceEndpoints
  delegations: subnetDelegation
} : nsgName != '' && routeTableName == '' ? {
  addressPrefix: addressPrefix
  networkSecurityGroup: {
    id: resourceId('Microsoft.Network/networkSecurityGroups', nsgName)
  }
  serviceEndpoints: serviceEndpoints
  delegations: subnetDelegation
} : {
  addressPrefix: addressPrefix
  routeTable: {
    id: resourceId('Microsoft.Network/routeTables', routeTableName)
  }
  networkSecurityGroup: {
    id: resourceId('Microsoft.Network/networkSecurityGroups', nsgName)
  }
  serviceEndpoints: serviceEndpoints
  delegations: subnetDelegation
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2021-08-01' = {
  name: subnetName 
  parent: vnet 
  properties: properties  
}

output subnetId string = subnet.id
