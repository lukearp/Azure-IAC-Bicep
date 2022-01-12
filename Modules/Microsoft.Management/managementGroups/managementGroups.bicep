targetScope = 'tenant'
param displayName string
param id string
param parentId string = ''
param subscriptions array = []

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

module childSubs 'subscriptions/subscriptions.bicep' = if(subscriptions != []) {
  name: '${managementGroup.name}-Subscriptions'
  params: {
    managementGroupName: managementGroup.name
    subscriptions: subscriptions 
  }  
}

output id string = managementGroup.id
