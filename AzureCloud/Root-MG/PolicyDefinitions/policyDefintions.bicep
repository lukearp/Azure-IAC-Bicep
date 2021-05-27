targetScope = 'managementGroup'
var policies = [
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
    }
    policyRule: {
      if: {
        not: {
          field: 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings/remoteVirtualNetwork.id'
          equals: '[parameters(\'hubVNETId\')]'
        }
      }
      then: {
        effect: 'deny'
      }
    }
  }
  {
    name: 'Append-Standard-NSG-Rules'
    mode: 'All'
    displayName: 'Append Standard NSG Rules'
    category: 'Network'
    policyRule: {
      if: {
        allOf: [
          {
            field: 'type'
            equals: 'Microsoft.Network/networkSecurityGroups'
          }
          {
            not: {
              field: 'Microsoft.Network/networkSecurityGroups/subnets[*].delegations[*].type'
              equals: 'Microsoft.Sql/managedInstances'
            }
          }
        ]
      }
      then: {
        effect: 'append'
        details: [
          {
            field: 'Microsoft.Network/networkSecurityGroups/securityRules'
            value: '[parameters(\'defaultSecurityRules\')]'
          }
        ]
      }
    }
    parameters: {
      defaultSecurityRules: {
        type: 'Array'
        metadata: {
          description: 'Default Security Rules'
        }
      }
    }
  }
  {
    name: 'Protect-Standard-NSG-Rules'
    mode: 'All'
    displayName: 'Protect Standard NSG Rules'
    category: 'Network'
    policyRule: {
      if: {
        allOf: [
          {
            field: 'type'
            equals: 'Microsoft.Network/networkSecurityGroups/securityRules'
          }
          {
            field: 'Microsoft.Network/networkSecurityGroups/securityRules/priority'
            greaterOrEquals: '[parameters(\'startingPriority\')]'
          }
          {
            field: 'Microsoft.Network/networkSecurityGroups/securityRules/priority'
            lessOrEquals: '[parameters(\'endingPriority\')]'
          }
        ]
      }
      then: {
        effect: 'deny'
      }
    }
    parameters: {
      startingPriority: {
        type: 'integer'
        metadata: {
          description: 'Starting Priority'
        }
      }
      endingPriority: {
        type: 'integer'
        metadata: {
          description: 'Ending Priority'
        }
      }
    }
  }
]
module policy '../../../Modules/Microsoft.Authorization/policyDefinitions/policyDefinitions-mg-array.bicep' = {
  name: 'PolicyDefinitions-Deploy'
  params: {
    policies: policies
  }
}

output policyOutputs array = policy.outputs.policyIds
