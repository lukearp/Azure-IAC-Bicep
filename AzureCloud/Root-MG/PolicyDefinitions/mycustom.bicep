targetScope = 'managementGroup'
module policy '../../../Modules/Microsoft.Authorization/policyDefinitions/policyDefinitions-mg.bicep' = {
  name: 'MyCustomPolicy'
  params: {
    dispalyName: 'This is my Custom Policy'
    mode: 'All'
    name: 'TheCustomPolicyBicep'
    parameters: {
      myParam: {
        type: 'string'
        metadata: {
          description: 'Test'
        }
      }
    }
    policyRule: {
      if: {
        not: {
          field: 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings/remoteVirtualNetwork.id'
          equals: '[parameters(\'myParam\')]'
        }
      }
      then: {
        effect: 'deny'
      }
    }
  }
}
