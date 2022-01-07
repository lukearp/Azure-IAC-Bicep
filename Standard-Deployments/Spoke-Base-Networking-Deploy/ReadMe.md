# What does this module do?
Deploys a standard spoke VNET that is peered to a HUB VNET.  Designed to be used as a Blueprint Artifact.  Can modify Address Space of existing VNETs and add Additional Subnets.  Designed to allow config drift from the base blueprint, and then configure properties if currently not set.  

Template Deploys:
1. Virtual Network
2. Network Security Groups
3. Route Table

# What does this module Require?
If deployed as a standard Template, the user would need rights to both the target Resource Group of the spoke and the HUB VNET resource group.  

# Parameters
param | type | notes
------|------|------
vnetName | string | Name of Spoke Virtual Network
resourceGroupName | string | Name of Resource Group that Spoke VNET will be deployed too
projectTagValue | string | Value of Tag named Project
existingVnet | bool | Is the Spoke VNET Already deployed true or false
addressspaceOctet3int | int | 3rd Octect of the IPv4 address space.  The first two are vars in the template
CIDR | string | CIDR value for the VNET Address Space
dnsServers | array | Array of DNS Server IPs
additionalSubnet | bool | Are you deploying new Subnets to an existing VNET true or false
subnets | array | Array of Azure ARM Subnet Objects.  If additionalSubnets is true, the subnets will be considered new to an existing VNET.
hubVnetId | string | Resource ID of the HUB VNET
hubAddressSpace | string | Address space of the HUB VNET
location | string | Azure region
nvaIp | string | IPv4 address of the NVA (Firewall Appliance)
additionalAddressSpace | array | Array of Address spaces to be added to the VNET.  updateAddressSpace must = true
updateAddressSpace | bool | Add additional address space true or false
userManagedIdentityId | string | Resource ID of a managed identity to handle Peer Deletions for Updated Address Space
gatewayRtId | string | Resource ID of the Route Table on the Gateway Subnet to ensure symmetric routing. 


# Sample Module

