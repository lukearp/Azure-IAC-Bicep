targetScope = 'managementGroup'
param name string
param displayName string
param policyDefinitions array
param policyDefinitionGroups array
param parameters object

resource policySet 'Microsoft.Authorization/policySetDefinitions@2020-09-01' = {
  name: name
  properties: {
    displayName: displayName
    policyDefinitionGroups: policyDefinitionGroups
    policyDefinitions: policyDefinitions
    parameters: parameters  
  } 
}
