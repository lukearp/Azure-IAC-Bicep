targetScope = 'managementGroup'

var requiredTagsOnRgs = [
  'Environment'
  'CostCode'
  'Backup'
]

var policyDefinitionGroups = [
  {
    name: 'Tags'
    displayName: 'Tag Policies'
    category: 'Tags'
  }
  {
    name: 'Monitor'
    displayName: 'Monitor Policies'
    category: 'Monitor'
  }
  {
    name: 'NetworkSecurity'
    displayName: 'Network Security Policies'
    category: 'Network'
  }
  {
    name: 'ResourceRestriction'
    displayName: 'Resource Level Restrictions'
    category: 'Resource'
  }
  {
    name: 'Recovery'
    displayName: 'Recovery Services'
    category: 'BCDR'
  }
]

var defaultLocations = [
  'eastus'
  'eastus2'
  'centralus'
  'westus'
]

var taggingPoliciesRg = [for tags in requiredTagsOnRgs: {
  policyDefinitionId: '/providers/Microsoft.Authorization/policyDefinitions/96670d01-0a4d-4649-9c89-2d3abc0a5025'
    groupNames: [
      'Tags'
    ]
    parameters: {
      tagName: {
        value: '${tags}'
      }
    }
}]

var taggingInheritencePolicy = [for tags in requiredTagsOnRgs: {
  policyDefinitionId: '/providers/Microsoft.Authorization/policyDefinitions/cd3aa116-8754-49c9-a813-ad46512ece54'
    groupNames: [
      'Tags'
    ]
    parameters: {
      tagName: {
        value: '${tags}'
      }
    }
}]

var staticPolicyDefs = [
  {//Policy for enabling VM Loging to Azure Monitor Windows    
    policyDefinitionId: '/providers/Microsoft.Authorization/policyDefinitions/0868462e-646c-4fe3-9ced-a733534b6a2c'
    groupNames: [
      'Monitor'
    ]
    parameters: {
      logAnalytics: {
        value: '[parameters(\'logAnalytics\')]'
      }
      listOfImageIdToInclude: {
        value: '[parameters(\'listOfImageIdToInclude\')]'
      }
    }
  }    
  {//Restrict Resource Group locations deploy
    policyDefinitionId: '/providers/Microsoft.Authorization/policyDefinitions/e765b5de-1225-4ba3-bd56-1ac6695af988'
    groupNames: [
      'ResourceRestriction'
    ]
    parameters: {
      listOfAllowedLocations: {
        value: '[parameters(\'listOfAllowedLocations\')]'
      }
    }
  }  
  {//Restrict Resource locations deploy
    policyDefinitionId: '/providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c'
    groupNames: [
      'ResourceRestriction'
    ]
    parameters: {
      listOfAllowedLocations: {
        value: '[parameters(\'listOfAllowedLocations\')]'
      }
    }
  }
  {//Primary Region Backup
    policyDefinitionId: '/providers/Microsoft.Authorization/policyDefinitions/09ce66bc-1220-4153-8104-e3f51c936913'
    groupNames: [
      'Recovery'
    ]
    parameters: {
      vaultLocation: {
        value: '[parameters(\'primaryRegion\')]'
      }
      backupPolicyId: {
        value: '[parameters(\'backupPolicyId\')]'
      }
      exclusionTagName: {
        value: 'Backup'
      }
      exclusionTagValue: {
        value: '[array(\'no\')]'
      }
      effect: {
        value: '[parameters(\'backupPolicyEffect\')]'
      }
    }
  }
  /*{//DR Configuration
    policyDefinitionId: '/providers/Microsoft.Authorization/policyDefinitions/ac34a73f-9fa5-4067-9247-a3ecae514468'
    groupNames: [
      'Recovery'
    ]
    parameters: {
      sourceRegion: {
        value: '[parameters(\'primaryRegion\')]'
      }
      targetRegion: {
        value: '[parameters(\'secondaryRegion\')]'
      }
      targetResourceGroupId: {
        '[]'
      }
    }
  }*/
]

var policyDefinitions = concat(taggingPoliciesRg,taggingInheritencePolicy,staticPolicyDefs)

module enterpriseInitiative '../../Modules/Microsoft.Authorization/policySetDefinitions/policySetDefinitions-mg.bicep' = {
  name: 'Enterprise-Initiative'
  params: {
    displayName: 'Enterprise-Initiative'
    policyDefinitionGroups: policyDefinitionGroups
    name: 'Enterprise-Initiative'
    parameters: {
      logAnalytics: {
        type: 'String'
        metadata: {
          strongType: 'omsWorkspace'
          assignPermissions: true
          displayName: 'Log Analytics workspace'
        }
      }
      listOfImageIdToInclude: {
        type: 'Array'
        metadata: {
          displayName: 'Optional: List of virtual machine images that have supported Windows OS to add to scope'
          description: 'Example values: \'/subscriptions/<subscriptionId>/resourceGroups/YourResourceGroup/providers/Microsoft.Compute/images/ContosoStdImage\''
        }
        defaultValue: []
      }
      listOfAllowedLocations: {
        type: 'Array'
        metadata: {
          displayName: 'Allowed locations'
          description: 'The list of locations that resource groups can be created in.'
          strongType: 'location'
        }
        defaultValue: defaultLocations
      }
      primaryRegion: {
        type: 'String'
        metadata: {
          displayName: 'Primary Azure Region'
          description: 'The primary deployment region for your Azure DataCenter'
          strongType: 'location'
        }
        defaultValue: 'eastus'
      }
      backupPolicyEffect: {
        type: 'String'
        allowedValues: [
          'disabled'
          'deployIfNotExists'
        ]
        metadata: {
          displayName: 'Enable VM Backup'
          description: 'Enables VM Backup on VMs'
        }
        defaultValue: 'disabled'
      }
      backupPolicyId: {
        type: 'String'
        defaultValue: ''
        metadata: {
          displayName: 'Backup Policy ID'
        }
      }
    }
    policyDefinitions: policyDefinitions
  }
}
