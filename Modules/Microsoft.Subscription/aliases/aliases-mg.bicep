targetScope = 'tenant'
@description('Provide a name for the alias. This name will also be the display name of the subscription.')
param subscriptionAliasName string
@description('Provide the full resource ID of billing scope to use for subscription creation.')
param billingScope string
@description('Provide the EA Subscription Type - Either Production or DevTest')
@allowed([
  'Production'
  'DevTest'
])
param subscriptionType string
resource subscriptionAliasName_resource 'Microsoft.Subscription/aliases@2020-09-01' = {
  scope: tenant()
  name: subscriptionAliasName
  properties: {
    workload: subscriptionType
    displayName: subscriptionAliasName
    billingScope: billingScope
  }
}
output newSubID string = subscriptionAliasName_resource.properties.subscriptionId
