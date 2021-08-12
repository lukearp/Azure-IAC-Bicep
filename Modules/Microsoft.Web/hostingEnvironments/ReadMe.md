# What does this module do?
Deploys an ASE (Currently V2 only) to an existing Subnet.  The Subnet must be dedicated for the ASE

# What does this module require?
A Virtual Network that has a dedicated Subnet (minimum of /27 but /24 is recommended) for the ASE Deployment.

If a NSG is on the ASE Subnet, the following Inbound rules need to be allowed
Use | From | To
----|------|----
Management | App Service management addresses | ASE Subnet
ASE internal communication | ASE Subnet | ASE Subnet
Allow Azure load balancer inbound | Azure Load Balancer | ASE subnet Port 16001/tcp

# Parameters
param | type | notes
------|------|------
name | string | Name of the App Service Environment
kind | string | Currently only allowed ASEV2
location | string | Azure Region
tags | object | Azure Resource Tags
virtualNetworkName | string | Name of target VNET
virtualNetworkRg | string | Name of VNET Resource Group
aseSubnetName | string | Name of dedicated ASE Subnet
internalLoadBalancingMode | string | Load Balancing Mode, options 'None' External ASE, 'Web' ILB With 80/443 only, 'Publishing' ILB with FTP Only, 'Web, Publishing' ISB with 80/443 and FTP
ipsslAddressCount | string | Number of IP SSL addresses reserved for the App Service Environment.