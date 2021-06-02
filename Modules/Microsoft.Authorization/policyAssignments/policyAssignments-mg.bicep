targetScope = 'managementGroup'
param name string
param policyId string
param parameters object

resource policyAssignment 'Microsoft.Authorization/policyAssignments@2020-09-01' = {
  name: name
  properties: {
    policyDefinitionId: policyId 
    parameters: parameters
  }
}
