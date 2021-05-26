targetScope = 'managementGroup'
var policies = [
  {
    name: 'VNET-to-Hub-Peering-Enforcement'
    displayName: 'Restricts VNET peering to HUB VNET Only'
    mode: 'All'
    category: 'BicepTest'
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
    category: 'BicepTest'
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
]
module policy '../../../Modules/Microsoft.Authorization/policyDefinitions/policyDefinitions-mg-array.bicep' = {
  name: 'PolicyDefinitions-Deploy'
  params: {
    policies: policies
  }
}

output policyOutputs array = policy.outputs.policyIds
