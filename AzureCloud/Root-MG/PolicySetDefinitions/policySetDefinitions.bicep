targetScope = 'managementGroup'
module customPolicies '../PolicyDefinitions/policyDefintions.bicep' = {
  name: 'customPolicies'
}

var policyDefinitionGroups = [
  {
    name: 'Tags'
    displayName: 'Tag Policies'
    category: 'Tags'  
  }
  {
    name: 'Network'
    displayName: 'Network Policy'
    category: 'Network'
  }
  {
    name: 'Location'
    displayName: 'Allowed Locations'
    category: 'Location'
  }
]

module policySet '../../../Modules/Microsoft.Authorization/policySetDefinitions/policySetDefinitions-mg.bicep' = {
  name: 'PolicySet-def'
  params: {
    displayName: 'Executive Initiative' 
    name: 'Executive-Initiative'
    parameters: {
      starting: {
        type: 'integer'
        defaultValue: 4000
      }
      ending: {
        type: 'integer'
        defaultValue: 4096
      }
      hubVnetResourceId: {
        type: 'string'
        defaultValue: ''
      }
      standardNsgRules: {
        type: 'array'
        defaultValue: []
      }
      tag1: {
        type: 'string'
        defaultValue: 'agency'
      }
      tag2: {
        type: 'string'
        defaultValue: 'environment'
      }
      tag3: {
        type: 'string'
        defaultValue: 'application'
      }
      tag4: {
        type: 'string'
        defaultValue: 'Name'
      }
      tag5: {
        type: 'string'
        defaultValue: 'createdby'
      }
      tag6: {
        type: 'string'
        defaultValue: 'businessowner'
      }
      tag7: {
        type: 'string'
        defaultValue: 'itowner'
      }
      tag8: {
        type: 'string'
        defaultValue: 'backup'
      }
      listOfAllowedLocations: {
        type: 'Array'
        metadata: {
          description: 'The list of locations that resource groups can be created in.'
          strongType: 'location'
          displayName: 'Allowed locations'
        }
        defaultValue: [
          'eastus2'
          'global'
        ]
      }
    }
    policyDefinitionGroups: policyDefinitionGroups
    policyDefinitions: [
      {
        policyDefinitionId: '/providers/Microsoft.Management/managementGroups/Luke-Root/providers/Microsoft.Authorization/policyDefinitions/Protect-Standard-NSG-Rules'
        groupNames: [
          'Network'
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
        policyDefinitionId: '/providers/Microsoft.Authorization/policyDefinitions/96670d01-0a4d-4649-9c89-2d3abc0a5025'
        groupNames: [
          'Tags'
        ]
        parameters: {
          tagName: {
            value: '[parameters(\'tag1\')]'
          }
        }
      }
      {
        policyDefinitionId: '/providers/Microsoft.Authorization/policyDefinitions/96670d01-0a4d-4649-9c89-2d3abc0a5025'
        groupNames: [
          'Tags'
        ]
        parameters: {
          tagName: {
            value: '[parameters(\'tag2\')]'
          }
        }
      }
      {
        policyDefinitionId: '/providers/Microsoft.Authorization/policyDefinitions/96670d01-0a4d-4649-9c89-2d3abc0a5025'
        groupNames: [
          'Tags'
        ]
        parameters: {
          tagName: {
            value: '[parameters(\'tag3\')]'
          }
        }
      }
      {
        policyDefinitionId: '/providers/Microsoft.Authorization/policyDefinitions/96670d01-0a4d-4649-9c89-2d3abc0a5025'
        groupNames: [
          'Tags'
        ]
        parameters: {
          tagName: {
            value: '[parameters(\'tag4\')]'
          }
        }
      }
      {
        policyDefinitionId: '/providers/Microsoft.Authorization/policyDefinitions/96670d01-0a4d-4649-9c89-2d3abc0a5025'
        groupNames: [
          'Tags'
        ]
        parameters: {
          tagName: {
            value: '[parameters(\'tag5\')]'
          }
        }
      }
      {
        policyDefinitionId: '/providers/Microsoft.Authorization/policyDefinitions/96670d01-0a4d-4649-9c89-2d3abc0a5025'
        groupNames: [
          'Tags'
        ]
        parameters: {
          tagName: {
            value: '[parameters(\'tag6\')]'
          }
        }
      }
      {
        policyDefinitionId: '/providers/Microsoft.Authorization/policyDefinitions/96670d01-0a4d-4649-9c89-2d3abc0a5025'
        groupNames: [
          'Tags'
        ]
        parameters: {
          tagName: {
            value: '[parameters(\'tag7\')]'
          }
        }
      }
      {
        policyDefinitionId: '/providers/Microsoft.Authorization/policyDefinitions/96670d01-0a4d-4649-9c89-2d3abc0a5025'
        groupNames: [
          'Tags'
        ]
        parameters: {
          tagName: {
            value: '[parameters(\'tag8\')]'
          }
        }
      }
      {
        policyDefinitionId: '/providers/Microsoft.Authorization/policyDefinitions/cd3aa116-8754-49c9-a813-ad46512ece54'
        groupNames: [
          'Tags'
        ]
        parameters: {
          tagName: {
            value: '[parameters(\'tag1\')]'
          }
        }
      }
      {
        policyDefinitionId: '/providers/Microsoft.Authorization/policyDefinitions/cd3aa116-8754-49c9-a813-ad46512ece54'
        groupNames: [
          'Tags'
        ]
        parameters: {
          tagName: {
            value: '[parameters(\'tag2\')]'
          }
        }
      }
      {
        policyDefinitionId: '/providers/Microsoft.Authorization/policyDefinitions/cd3aa116-8754-49c9-a813-ad46512ece54'
        groupNames: [
          'Tags'
        ]
        parameters: {
          tagName: {
            value: '[parameters(\'tag3\')]'
          }
        }
      }
      {
        policyDefinitionId: '/providers/Microsoft.Authorization/policyDefinitions/cd3aa116-8754-49c9-a813-ad46512ece54'
        groupNames: [
          'Tags'
        ]
        parameters: {
          tagName: {
            value: '[parameters(\'tag4\')]'
          }
        }
      }
      {
        policyDefinitionId: '/providers/Microsoft.Authorization/policyDefinitions/cd3aa116-8754-49c9-a813-ad46512ece54'
        groupNames: [
          'Tags'
        ]
        parameters: {
          tagName: {
            value: '[parameters(\'tag5\')]'
          }
        }
      }
      {
        policyDefinitionId: '/providers/Microsoft.Authorization/policyDefinitions/cd3aa116-8754-49c9-a813-ad46512ece54'
        groupNames: [
          'Tags'
        ]
        parameters: {
          tagName: {
            value: '[parameters(\'tag6\')]'
          }
        }
      }
      {
        policyDefinitionId: '/providers/Microsoft.Authorization/policyDefinitions/cd3aa116-8754-49c9-a813-ad46512ece54'
        groupNames: [
          'Tags'
        ]
        parameters: {
          tagName: {
            value: '[parameters(\'tag7\')]'
          }
        }
      }
      {
        policyDefinitionId: '/providers/Microsoft.Authorization/policyDefinitions/cd3aa116-8754-49c9-a813-ad46512ece54'
        groupNames: [
          'Tags'
        ]
        parameters: {
          tagName: {
            value: '[parameters(\'tag8\')]'
          }
        }
      }
      {
        policyDefinitionId: '/providers/Microsoft.Authorization/policyDefinitions/83a86a26-fd1f-447c-b59d-e51f44264114' //Public IP
        groupNames: [
          'Network'
        ]
        parameters: {}  
      }
      {
        policyDefinitionId: '/providers/Microsoft.Management/managementGroups/Luke-Root/providers/Microsoft.Authorization/policyDefinitions/Append-Standard-NSG-Rules'
        groupNames: [
          'Network'
        ]
        parameters: {
          defaultSecurityRules: {
            value: '[parameters(\'standardNsgRules\')]'
          }
        }  
      }
      {
        policyDefinitionId: '/providers/Microsoft.Management/managementGroups/Luke-Root/providers/Microsoft.Authorization/policyDefinitions/VNET-to-Hub-Peering-Enforcement'
        groupNames: [
          'Network'
        ]
        parameters: {
          hubVNETId: {
            value: '[parameters(\'hubVnetResourceId\')]'
          }
        }  
      }
      { //Allowed Location for Resource Groups
        policyDefinitionId: '/providers/Microsoft.Authorization/policyDefinitions/e765b5de-1225-4ba3-bd56-1ac6695af988'
        groupNames: [
          'Location'
        ]
        parameters: {
          listOfAllowedLocations: {
            value: '[parameters(\'listOfAllowedLocations\')]'
          }
        }  
      }
      { //Allowed Location for Resources
        policyDefinitionId: '/providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c'
        groupNames: [
          'Location'
        ]
        parameters: {
          listOfAllowedLocations: {
            value: '[parameters(\'listOfAllowedLocations\')]'
          }
        }  
      }
    ]    
  } 
}

output policyId string = policySet.outputs.policyId
