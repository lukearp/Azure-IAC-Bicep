module sub '../../Modules/Microsoft.Subscription/aliases/aliases-mg.bicep' = {
  name: 'Test-Subscription'
  scope: tenant()
  params: {
    billingScope: 'test'
    subscriptionAliasName: 'Test-Sub' 
    workload: 'Production' 
  }  
}

module mg '../../Modules/Microsoft.Management/managementGroups/managementGroups.bicep' = {
  name: 'Root-MG'
  scope: tenant()
  params: {
    displayName: 'My Root Group'
    id: 'Root-MG'
    subscriptions: [
      sub.outputs.subId
    ]     
  }  
}
