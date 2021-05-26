targetScope = 'managementGroup'
module customPolicyIds '../PolicyDefinitions/policyDefinitions.bicep' = {
 name: 'CustomPolicies' 
}

var policyDefinitionGroups = [
  {
    name: 'Tags'
    displayName: 'Tag Policies'
    category: 'Tags'  
  }
  {
    name: 'BicepTest'
    displayName: 'Bicep Test Policies'
    category: 'BicepTest'
  }
]

module policySet '../../../Modules/Microsoft.Authorization/policySetDefinitions/policySetDefinitions-mg.bicep' = {
  name: 'PolicySet-def'
  dependsOn: [
    customPolicyIds
  ]
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
      hubVnetResourceId: {
        type: 'string'
        defaultValue: ''
      }
      standardNsgRules: {
        type: 'array'
        defaultValue: []
      }
    }
    policyDefinitionGroups: policyDefinitionGroups
    policyDefinitions: [
      {
        policyDefinitionId: '/providers/Microsoft.Management/managementGroups/LukeInternal/providers/Microsoft.Authorization/policyDefinitions/3d4214c5-1dbe-401a-9fc1-50c395978c21'
        groupNames: [
          'BicepTest'
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
      {
        policyDefinitionId: '/providers/Microsoft.Management/managementGroups/LukeInternal/providers/Microsoft.Authorization/policyDefinitions/Append-Standard-NSG-Rules'
        groupNames: [
          'BicepTest'
        ]
        parameters: {
          defaultSecurityRules: {
            value: '[parameters(\'standardNsgRules\')]'
          }
        }  
      }
      {
        policyDefinitionId: '/providers/Microsoft.Management/managementGroups/LukeInternal/providers/Microsoft.Authorization/policyDefinitions/VNET-to-Hub-Peering-Enforcement'
        groupNames: [
          'BicepTest'
        ]
        parameters: {
          hubVNETId: {
            value: '[parameters(\'hubVnetResourceId\')]'
          }
        }  
      }
    ]    
  } 
}
