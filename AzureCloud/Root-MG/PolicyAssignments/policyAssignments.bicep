targetScope = 'managementGroup'
param assignmentName string = 'My-Initiative-Assignment'
param policyName string = 'Executive-Initiative'
param policyManagementGroup string = 'LukeInternal'
param parameters object = {
  starting: {
    value: 4000
  }
  ending: {
    value: 4096
  }
  hubVnetResourceId: {
    value: '/subscriptions/4bb3900a-62d5-41a8-a02c-1b811cf079c7/resourceGroups/rg_paloalto_eastus/providers/Microsoft.Network/virtualNetworks/fwVNET'
  }
  standardNsgRules: {
    value: [
      {
        name: 'SSH2'
        properties: {
          protocol: 'TCP'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '35.132.216.178'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 3000
          direction: 'Inbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
    ]
  }
}

resource definition 'Microsoft.Authorization/policySetDefinitions@2020-09-01' existing = {
  name: policyName
  scope: managementGroup(policyManagementGroup)
}

module assignment '../../../Modules/Microsoft.Authorization/policyAssignments/policyAssignments-mg.bicep' = {
  name: 'Assignment'
  params: {
    name: assignmentName
    policyId: definition.id
    parameters: parameters
    location: 'eastus'
  }
}
