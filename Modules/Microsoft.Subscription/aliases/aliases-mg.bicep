targetScope = 'tenant'
param subscriptionAliasName string
param billingScope string

resource subscriptionAlias 'Microsoft.Subscription/aliases@2019-10-01-preview' = {
  name: subscriptionAliasName
  properties: {
    workload: 'Production' 
    billingScope: billingScope
    displayName: subscriptionAliasName     
  }  
}

output subId string = subscriptionAlias.id
