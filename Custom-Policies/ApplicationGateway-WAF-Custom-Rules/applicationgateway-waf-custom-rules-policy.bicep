targetScope = 'managementGroup'

@description('Name of the custom policy definition.')
param policyDefinitionName string = 'deploy-applicationgateway-waf-custom-rules'

var definition = loadJsonContent('./applicationgateway-waf-custom-rules-policy-properties.json')

resource policyDefinition 'Microsoft.Authorization/policyDefinitions@2023-04-01' = {
  name: policyDefinitionName
  properties: definition.properties
}

output policyDefinitionId string = policyDefinition.id
output policyDefinitionName string = policyDefinition.name
