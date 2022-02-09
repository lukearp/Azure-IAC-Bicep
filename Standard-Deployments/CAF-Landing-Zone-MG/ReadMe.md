# What does this module do?
Creates Management Group Hierarchy per [CAF Guidance]("https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone/design-area/resource-org-management-groups"). 

# What does this module Require?
Must be deployed by a user that has rights to do deployments at the Tenant Level.

# Parameters
param | type | notes
------|------|------
rootMgName | string | The Name of the Root Management group that will be created
platformMgName | string | The name of the Platform Management Group
platformChildMgs | array | Array of Names of Child Management Groups under Platform
landingZoneMgName | string | The name of the Landing Zone Management Group
landingZoneChildMgs | array | Array of Names of Child Management Groups under Landing Zone
existingSubscriptions | array | Array of objects to move existing Azure Subscriptions to a deployed Management Group

Example of existingSubscriptions object:
{
    mg: 'Management Group Name'
    id: 'Subscription ID'
}

# Sample Module

```Bicep
  targetScope = 'tenant'
  module CAFMG 'Standard-Deployments/CAF-Landing-Zone-MG/caf-mg-deploy.bicep' = {
      name: 'CAF-MG'
      params: {
         rootMgName: 'My-Root'
         platformMgName: 'My-Platform'
         platformChildMgs: [
             'Connectivity'
             'Identity'
         ]
         landingZoneMgName: 'My-LZ'
         landingZoneChildMgs: [
             'Finance'
             'IT'
         ]
         existingSubscriptions: [
            {
                mg: 'Connectivity'
                id: 'SUBID'
            } 
         ] 
      }
  }
}
```