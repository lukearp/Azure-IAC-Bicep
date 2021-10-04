targetScope = 'managementGroup'
param name string
param location string
param description string
@allowed([
  'SystemAssigned'
  'UserAssigned'
])
param identityType string = 'SystemAssigned'
param userAssignedIdentityId string = ''
param blueprintId string
param blueprintVersion string
param parameters object = {}
param resourceGroups object = {}
@allowed([
  'None'
  'AllResourcesReadOnly'
  'AllResourcesDoNotDelete'
])
param lockMode string
param excludedPrincipals array = []
param excludedActions array = []
param scope string

var blueprintAssignId = '${blueprintId}/versions/${blueprintVersion}'
var identity = identityType == 'SystemAssigned' ? {
  type: identityType
}:{
  type: identityType 
  userAssignedIdentities: {
    '${userAssignedIdentityId}': {}  
  }
} 
resource assignment 'Microsoft.Blueprint/blueprintAssignments@2018-11-01-preview' = {
  name: name
  identity: identity
  location: location 
  properties: {
    locks: {
      excludedActions: excludedActions
      excludedPrincipals: excludedPrincipals 
      mode: lockMode 
    } 
    blueprintId: blueprintAssignId 
    scope: scope
    parameters: parameters
    resourceGroups: {}    
  } 
}
