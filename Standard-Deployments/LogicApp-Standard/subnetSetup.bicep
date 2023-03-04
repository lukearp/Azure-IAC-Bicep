param subnetId string
param properties object 

resource vnet 'Microsoft.Network/virtualNetworks@2022-07-01' existing = {
  name: split(subnetId,'/')[8] 
}

var delegationProperty = union(properties,{
  delegations: [{
    name: 'delegation'
    properties: {
      serviceName: 'Microsoft.Web/serverFarms'
    } 
  }]
})

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2022-07-01' = {
  name: split(subnetId,'/')[10]
  parent: vnet 
  properties: delegationProperty 
}
