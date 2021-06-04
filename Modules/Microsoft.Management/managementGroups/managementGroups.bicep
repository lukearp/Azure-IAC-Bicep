targetScope = 'tenant'
param displayName string
param id string
param parentId string
param subscriptions array

var details = parentId != '' ? {
  parent: {
    id: '/providers/Microsoft.Management/managementGroups/${parentId}'
  }
} : {}

resource managementGroup 'Microsoft.Management/managementGroups@2021-04-01' = {
  name: id
  properties: {
    displayName: displayName 
    details: details
  }  
}

resource childSubscriptions 'Microsoft.Management/managementGroups/subscriptions@2021-04-01' = [for sub in subscriptions : {
  name: '${managementGroup.name}/${sub}' 
}]
