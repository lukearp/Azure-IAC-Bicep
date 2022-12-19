# What does this module do?
Deploys a query pack with standard queries I use to monitor and buid dashboards for IaaS Workloads

# What does this module Require?
For all the queries to return data, you will need server logging their System, Application, and Security event logs to the workspace at a Informational level.

# Parameters

param | type | notes
------|------|------
queryPackName | string | Name of Query Pack
location | string | Azure region.  Ex: eastus

# Sample Module

```
module queryPack './Standard-Deployments/Azure-IaaS-QueryPack/query.bicep' = {
    name: 'Pack-Deploy'
    scope: resourceGroup('rgName')
    params: {
        queryPackName: 'My-Pack-Name'
        location: 'eastus'
    }
}
```