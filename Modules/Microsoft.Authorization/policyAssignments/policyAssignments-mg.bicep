targetScope = 'managementGroup'
param name string
param policyId string
param parameters object
param location string
param notScopes array

resource policyAssignment 'Microsoft.Authorization/policyAssignments@2021-06-01' = {
  name: name
  properties: {
    policyDefinitionId: policyId 
    parameters: parameters 
    notScopes: notScopes
  }
  identity: {
    type: 'SystemAssigned'  
  }
  location: location  
}
