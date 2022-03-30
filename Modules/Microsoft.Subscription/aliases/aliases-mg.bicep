targetScope = 'tenant'
param subscriptionAliasName string
param billingScope string
@allowed([
  'Production'
  'DevTest'
])
param workload string = 'Production'

resource subscriptionAlias 'Microsoft.Subscription/aliases@2020-09-01' = {
  name: subscriptionAliasName
  properties: {
    workload: workload 
    billingScope: billingScope
    displayName: subscriptionAliasName     
  }  
}

output subId string = split(subscriptionAlias.properties.subscriptionId,'/')[1]
