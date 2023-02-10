param location string
param name string
param initialAdmin string 
param disablePublicAccess bool = false
param strorageResourceId string
param storageDfsEndpoint string
param createPrivateEndpointForStorage bool = false
param sqlAdminUser string
@secure()
param sqlAdminPassword string
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
    publicNetworkAccess: disablePublicAccess == true ? 'Disabled' : 'Enabled' 
    managedVirtualNetwork: 'default'
    managedVirtualNetworkSettings: {
      allowedAadTenantIdsForLinking: [
        tenant().tenantId
      ] 
    }
    cspWorkspaceAdminProperties: {
      initialWorkspaceAdminObjectId: initialAdmin 
    }
    sqlAdministratorLogin: sqlAdminUser
    sqlAdministratorLoginPassword: sqlAdminPassword    
  }  
}

output synapsId string = synapse.id
