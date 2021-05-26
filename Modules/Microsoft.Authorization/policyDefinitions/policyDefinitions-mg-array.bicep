targetScope = 'managementGroup'
param policies array
/*[
  {
    name: 'string'
    mode: 'Indexed/All'
    displayName: 'String'
    category: string
    policyRule : {}
    parameters: {}
  }
]*/

resource policyArrary 'Microsoft.Authorization/policyDefinitions@2020-09-01' = [for policy in policies: {    
  name: policy.name
  properties: {
    displayName: policy.displayName
    mode: policy.mode
    policyRule: policy.policyRule
    policyType: 'Custom'
    parameters: policy.parameters 
    metadata: {
      category: policy.category
    }  
 }
}]

output policyIds array = [for (policy,i) in policies: {
  id: policyArrary[i].id
  category: policies[i].category
}]
