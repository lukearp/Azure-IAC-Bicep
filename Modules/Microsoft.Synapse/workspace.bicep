param location string
param name string
param strorageResourceId string
param storageDfsEndpoint string
param createPrivateEndpointForStorage bool = false
param tags object = {}

resource synapse 'Microsoft.Synapse/workspaces@2021-06-01' = {
  name: name
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  } 
  properties: {
    defaultDataLakeStorage: {
      resourceId: strorageResourceId
      accountUrl: storageDfsEndpoint
      createManagedPrivateEndpoint: createPrivateEndpointForStorage 
      filesystem: 'default'  
    }      
    publicNetworkAccess: 'Disabled' 
    managedVirtualNetwork: 'default'
    managedVirtualNetworkSettings: {
      allowedAadTenantIdsForLinking: [
        tenant().tenantId
      ] 
    }   
  }  
}

output synapsId string = synapse.id
