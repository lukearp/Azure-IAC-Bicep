targetScope = 'managementGroup'
param name string
param policyId string
param parameters object
param location string

resource policyAssignment 'Microsoft.Authorization/policyAssignments@2020-09-01' = {
  name: name
  properties: {
    policyDefinitionId: policyId 
    parameters: parameters 
  }
  identity: {
    type: 'SystemAssigned' 
  }
  location: location  
}
