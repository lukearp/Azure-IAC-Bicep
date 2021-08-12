param name string
param location string
param description string
@allowed([
  'None'
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
