# What does this module do?
Deploys a Synapse Workspace, default storage, and Private Link Endpoints.

# Dependencies
* Existing Virtual Network Subnet for Private Link Endpoints
* To access the workspace, you would need to deploy a Synapse Private Link Hub

# Parameters
param | type | notes
------|------|------
location | string | Azure Region
name | string | Name of Synapse Workspace
resourceGroupName | string | Resource Group Name for Synapse Workspace
privateLinkSubnetId | string | Resource ID Of subnet to deploy Private Link Endpoints in
tags | object | Resource Tags