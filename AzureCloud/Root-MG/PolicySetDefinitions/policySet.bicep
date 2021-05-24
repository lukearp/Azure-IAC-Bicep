targetScope = 'managementGroup'
module policySet '../../../Modules/Microsoft.Authorization/policySetDefinitions/policySetDefinitions-mg.bicep' = {
  name: 'PolicySet-def'
  params: {
    displayName: 'This Test Bicep' 
    name: 'BicepTest-Def'
    parameters: {
      starting: {
        type: 'integer'
      }
      ending: {
        type: 'integer'
      }
    }
    policyDefinitionGroups: [
      {
        name: 'MyGroup'
        displayName: 'This Bicep Group'
        category: 'Test'  
      }
    ]
    policyDefinitions: [
      {
        policyDefinitionId: '/providers/Microsoft.Management/managementGroups/LukeInternal/providers/Microsoft.Authorization/policyDefinitions/3d4214c5-1dbe-401a-9fc1-50c395978c21'
        groupNames: [
          'MyGroup'
        ]
        parameters: {
          startingPriority: {
            value: '[parameters(\'starting\')]'
          }
          endingPriority: {
            value: '[parameters(\'ending\')]'
          }
        }  
      }
    ]    
  } 
}
