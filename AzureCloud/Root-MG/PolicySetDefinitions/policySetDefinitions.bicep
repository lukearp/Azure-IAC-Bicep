targetScope = 'managementGroup'
module customPolicies '../PolicyDefinitions/policyDefintions.bicep' = {
  name: 'customPolicies'
}

var policyDefinitionGroups = [
  {
    name: 'HTTPS'
    displayName: 'HTTPS Policies'
    category: 'Network'  
  }
  {
    name: 'Public_IPs'
    displayName: 'Public IPs Policy'
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
    displayName: 'OIT Root Initiative' 
    name: 'OIT-Root-Initiative'
    parameters: {      
      listOfAllowedLocations: {
        type: 'Array'
        metadata: {
          description: 'The list of locations that resource groups can be created in.'
          strongType: 'location'
          displayName: 'Allowed locations'
        }
        defaultValue: [
        ]
      }
    }
    policyDefinitionGroups: policyDefinitionGroups
    policyDefinitions: [
      {
        policyDefinitionId: '/providers/Microsoft.Authorization/policyDefinitions/83a86a26-fd1f-447c-b59d-e51f44264114'
        groupNames: [
          'Public_IPs'
        ]
        parameters: {
        }  
      }
      {
        policyDefinitionId: '/providers/Microsoft.Authorization/policyDefinitions/a4af4a39-4135-47fb-b175-47fbdf85311d'
        groupNames: [
          'HTTPS'
        ]
        parameters: {
        }  
      }
      {
        policyDefinitionId: '/providers/Microsoft.Authorization/policyDefinitions/6d555dd1-86f2-4f1c-8ed7-5abae7c6cbab'
        groupNames: [
          'HTTPS'
        ]
        parameters: {
        }  
      } 
      {
        policyDefinitionId: '/providers/Microsoft.Authorization/policyDefinitions/b7ddfbdc-1260-477d-91fd-98bd9be789a6'
        groupNames: [
          'HTTPS'
        ]
        parameters: {
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
