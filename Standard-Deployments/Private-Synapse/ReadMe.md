# What does this module do?
> Deploys a Synapse Workspace, default storage, and Private Link Endpoints.

> Optional: DNS Zones and A Records for Zones

# Dependencies
* Existing Virtual Network Subnet for Private Link Endpoints
* Ability to resolve and route Private Endpoint IPs

# Parameters
param | type | notes
------|------|------
location | string | Azure Region
name | string | Name of Synapse Workspace
resourceGroupName | string | Resource Group Name for Synapse Workspace
privateLinkSubnetId | string | Resource ID Of subnet to deploy Private Link Endpoints in
disablePublicAccess | bool | Disable public network access to the workspace
initialAdmin | string | UPN of Synapse Admin User
sqlAdminUser | string | Default SQL Admin User
sqlAdminPassword | securestring | Default SQL Password
addDNSRecords | bool | Create Private DNS Zones and Records
dnsSubscriptionId | string | Subscription to where DNS Zones and Records are to be deployed
dnsRgName | string | Resource Group to where the DNS Zones and Records are to be deployed
azureGovernment | bool | Deploy in Azure Government, default: false
autoApprovePLToStorage | bool | Approve the PL Endpoint from Synapse on the Azure Blob Storage.  Requires a Managed Identity that has rights to approve the PL Endpoint on the storage.  
managedIdentityId | string | Resource ID of a Managed Identity to approve the PL from Synapse.  Only needed if autoApprovePLToStorage = true
tags | object | Resource Tags

# Example

```bicep
targetScope = 'subscription'
module synapse '../Standard-Deployments/Private-Synapse/synapse-private.bicep' = {
  name: 'Synapse-Deploy'
  params: {
    initialAdmin: 'user@user.com'
    location: 'eastus'
    name: 'syanpse-workspace'
    privateLinkSubnetId: '/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxx/resourceGroups/network-rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/pl'
    resourceGroupName: 'Synapse_RG'
    sqlAdminPassword: 'PASSWORD'
    sqlAdminUser: 'localadmin'
    dnsSubscriptionId: subscription().subscriptionId
    dnsRgName: 'DNS-RG'
    tags: {
      Environment: 'Test'
    }    
    addDNSRecords: true     
  }  
}
```