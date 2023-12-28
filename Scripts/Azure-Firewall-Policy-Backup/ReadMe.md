# What does this do?

Explorts an Azure Firewall Policy, gets all referenced IP Groups, and properly sets the dependsOn for RuleCollectionGroups for easy redeploy.  

Easy way to keep your Firewall Policies backed up and check differences over time. 

# Parameters
param | type | notes
------|------|------
firewallPolicyId | String | Firewall Policy Resource ID you want to backup
fileName | String | Name of output file.

# Example
```powershell
.\Azure-Firewall-Policy-Backup.ps1 -firewallPolicyId "/subscriptions/XXXXXXX-XXXX-XXXX-XXXX-XXXXXX/resourceGroups/firewall-policies/providers/Microsoft.Network/firewallPolicies/Parent-Policy" -fileName "policy-backup.json"
```