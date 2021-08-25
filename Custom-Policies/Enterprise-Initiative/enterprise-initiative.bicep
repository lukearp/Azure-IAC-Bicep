targetScope = 'subscription'

var requiredTagsOnRgs = [
  'Environment'
  'CostCode'
  'Backup'
]

module customPolicyDefinitions '../../Modules/Microsoft.Authorization/policyDefinitions/policyDefinitions-sub-array.bicep' = {
  name: 'Restrict-VNET-PeeringPolicy'
  params: {
    policies: [
      {
        name: 'VNET-to-Hub-Peering-Enforcement'
        displayName: 'Restricts VNET peering to HUB VNET Only'
        mode: 'All'
        category: 'Network'
        parameters: {
          hubVNETId: {
            type: 'string'
            metadata: {
              description: '/subscriptions/XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXX/resourceGroups/RESOURCEGROUP/providers/Microsoft.Network/virtualNetworks/VNET'
            }
          }
          effect: {
            type: 'string'
            metadata: {
              description: 'Deny or Disabled'
            }
            allowedValues: [
              'deny'
              'disabled'
            ]
            defaultValue: 'deny'
          }
        }
        policyRule: {
          if: {
            not: {
              field: 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings/remoteVirtualNetwork.id'
              equals: '[parameters(\'hubVNETId\')]'
            }
          }
          then: {
            effect: '[parameters(\'effect\')]'
          }
        }
      }
      {
        name: 'Enforce-Resource-Group-and-Resource-Location-to-match'
        displayName: 'Enforce Resource Group and Resource Location to match'
        mode: 'Indexed'
        category: 'General'
        parameters: {
          effect: {
            type: 'String'
            allowedValues: [
              'deny'
              'disabled'
              'audit'
            ]
          }
        }
        policyRule: {
          if: {
            allOf: [
              {
                field: 'location'
                notEquals: '[resourcegroup().location]'
              }
              {
                field: 'location'
                notEquals: 'global'
              }
            ]
          }
          then: {
            effect: '[parameters(\'effect\')]'
          }
        }
      }
    ]
  }
}

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

var customPolicies = [
  {
    policyDefinitionId: customPolicyDefinitions.outputs.policyIds[0].id
      groupNames: [
        'NetworkSecurity'
      ]
      parameters: {
        hubVNETId: {
          value: '[parameters(\'hubVNETId\')]'
        }
        effect: {
          value: '[if(equals(parameters(\'enableVNETPeeringRestriction\'),true()),\'deny\',\'disabled\')]'
        }
      }
  }
  {
    policyDefinitionId: customPolicyDefinitions.outputs.policyIds[1].id
      groupNames: [
        'ResourceRestriction'
      ]
      parameters: {
        effect: {
          value: '[parameters(\'rgResourceLocationMatch\')]'
        }
      }
  }
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

var policyDefinitions = concat(taggingPoliciesRg,taggingInheritencePolicy,staticPolicyDefs,customPolicies)

module enterpriseInitiative '../../Modules/Microsoft.Authorization/policySetDefinitions/policySetDefinitions-sub.bicep' = {
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
      secondaryRegion: {
        type: 'String'
        metadata: {
          displayName: 'Secondary Azure Region'
          description: 'The secondary deployment region for your Azure DataCenter. Used for DR'
          strongType: 'location'
        }
        defaultValue: 'westus'
      }
      hubVNETId: {
        type: 'String'
        metadata: {
          displayName: 'Hub VNET Resource Id'
          description: 'VNET that Spokes are Allowed to Peer to'
        }
        defaultValue: ''
      }
      enableVNETPeeringRestriction: {
        type: 'Boolean'
        metadata: {
          displayName: 'Enable VNET Peering Restriction'
          description: 'Restrict VNET Peering to the Hub VNET only'
        }
        defaultValue: false
      }
      rgResourceLocationMatch: {
        type: 'String'
        allowedValues: [
          'audit'
          'deny'
          'disabled'
        ]
        metadata: {
          displayName: 'Enable Resource Group and Resource Location Match'
          description: 'Requires Resourc location to match Resource Group'
        }
        defaultValue: 'deny'
      }
    }
    policyDefinitions: policyDefinitions
  }
}
