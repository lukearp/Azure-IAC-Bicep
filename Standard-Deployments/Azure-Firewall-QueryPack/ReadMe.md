# What does this module do?
Deploys query pack to help Parse Azure Firewall ApplicationRule, NetworkRule, and DNAT rules.  

Allows to easily filter traffic by Source IP, Destination IP, Destination Port, and Action.

# What does this module Require?
Azure Firewall to be deployed and Diagnostic logs for AzureFirewallApplicationRule and AzureFirewallNetworkRule sent to a Log Analytics workspace.  

# Parameters

param | type | notes
------|------|------
queryPackName | string | Name of Query Pack
location | string | Azure region.  Ex: eastus

# Sample Module

```
module queryPack './Standard-Deployments/Azure-Firewall-QueryPack/querypack.bicep' = {
    name: 'Pack-Deploy'
    scope: resourceGroup('rgName')
    params: {
        queryPackName: 'My-Pack-Name'
        location: 'eastus'
    }
}
```