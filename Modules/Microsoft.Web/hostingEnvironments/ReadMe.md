# What does this module do?
Deploys an ASE (Currently V2 only) to an existing Subnet.  The Subnet must be dedicated for the ASE

# What does this module require?
A Virtual Network that has a dedicated Subnet (minimum of /27 but /24 is recommended) for the ASE Deployment.  Microsoft.Web/hostingEnvironment Subnet Delegation is required before deployment.

If a NSG is on the ASE Subnet, the following Inbound rules need to be allowed for ASEv2
Use | From | To
----|------|----
Management | App Service management addresses | ASE Subnet
ASE internal communication | ASE Subnet | ASE Subnet
Allow Azure load balancer inbound | Azure Load Balancer | ASE subnet Port 16001/tcp

# Parameters
param | type | notes
------|------|------
name | string | Name of the App Service Environment
kind | string | Currently only allowed ASEV2 and ASEV3
zoneRedundant | bool | Deploy accross availability zones.  Only valid for ASEV3
dedicatedHostCount | int | Run in Dedicated Hosts. Only valid for ASEV3
location | string | Azure Region
tags | object | Azure Resource Tags
virtualNetworkName | string | Name of target VNET
virtualNetworkRg | string | Name of VNET Resource Group
aseSubnetName | string | Name of dedicated ASE Subnet
internalLoadBalancingMode | string | Load Balancing Mode, options 'None' External ASE, 'Web' ILB With 80/443 only, 'Publishing' ILB with FTP Only, 'Web, Publishing' ISB with 80/443 and FTP
ipsslAddressCount | string | Number of IP SSL addresses reserved for the App Service Environment.

# Sample Module

```
module ase '../Modules/Microsoft.Web/hostingEnvironments/hostingEnvironments.bicep' = {
  name: 'ASE-Deploy'
  params: {
    aseSubnetName: 'ase'
    internalLoadBalancingMode: 'Web, Publishing'
    location: 'eastus2'
    name: 'testase'
    virtualNetworkName: 'testvnet'
    virtualNetworkRg: 'testvnetRg'        
  } 
}
```