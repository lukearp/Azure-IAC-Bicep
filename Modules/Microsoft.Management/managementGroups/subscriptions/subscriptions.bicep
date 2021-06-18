targetScope = 'tenant'
param managementGroupName string
param subscriptions array

resource childSubscriptions 'Microsoft.Management/managementGroups/subscriptions@2021-04-01' = [for sub in subscriptions : {
  name: '${managementGroupName}/${sub}' 
}]
