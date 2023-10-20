targetScope = 'managementGroup'
param name string
param roleDefinitionId string
param objectId string
param managementGroupName string

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(managementGroupName,name)
  properties: { 
    roleDefinitionId: roleDefinitionId
    principalId: objectId 
  }
}
