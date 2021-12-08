# What does this module do?
Creates a Private Link endpoint to a remote Azure service that doesn't live within your AAD Tenant

# What does this module Require?
An External Service ID, and the owner of the external service to approve the PrivateLink Endpoint conneciton.  

# Parameters
param | type | notes
------|------|------
name | string | Name of PrivateLink Endpoint
remoteServiceResourceId | string | Resource ID of remote service
targetSubResource | array | Sub resource. Ex: ['Sql'], default is []
subnetResourceId | string | Subnetnet resourceId to deploy the PrivateLink Endpoint in

# Sample Module

```Bicep
module pLink './privateEndpoints-remoteService.bicep' = {
    name: 'Deploy-Endpoint'
    scope: resourceGroup('myRg')
    properties: {
       name: 'My-PL'
       remoteServiceResourceId: '/subscriptions/xxxxx-xxxx-xxx-xxx/remoteService/ResourceID'
       targetSubResource: ['blob']
       subnetResourceId: '/subscriptions/xxxx-xxx-xxx/subnet/ResourceId'
    } 
}
```