# What does this module do?
Deploys Azure Management Group and can parent Azure Subscriptions.

# What does this module Require?
An account that can do Tenant Level Deployments

# Parameters
param | type | notes
------|------|------
displayName | string | Display name of the Management Group
id | string | Management Group
parentId | string | ID of Parent Management Group
subscriptions | string | array of Subscription IDs

# Sample

```bicep
targetScope = 'tenant'
module mg 'Modules/Microsoft.Management/managementGroups/managementGroups.bicep' = {
  name: 'MG-Create'
  scope: tenant()  
  params: {
    displayName: 'MG-Test'
    id: 'MG-Test' 
    subscriptions: [
      '000000-0000-0000-0000-0000000'
    ]  
  }  
}
```