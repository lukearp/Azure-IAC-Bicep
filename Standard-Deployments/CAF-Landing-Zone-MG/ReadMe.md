# What does this module do?
Creates Management Group Hierarchy per [CAF Guidance]("https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone/design-area/resource-org-management-groups"). 

# What does this module Require?
Must be deployed by a user that has rights to do deployments at the Tenant Level.  To use RBAC Assignments, you must have the Repo downloaded because it's dependant on my roleAssignments-mg.bicep file.

# Parameters
param | type | notes
------|------|------
rootMgName | string | The Name of the Root Management group that will be created
platformMgName | string | The name of the Platform Management Group
platformChildMgs | array | Array of Names of Child Management Groups under Platform
landingZoneMgName | string | The name of the Landing Zone Management Group
landingZoneChildMgs | array | Array of Names of Child Management Groups under Landing Zone
existingSubscriptions | array | Array of objects to move existing Azure Subscriptions to a deployed Management Group
rbacAssignments | array | Array of objects to assign RBAC to deployed Management Groups.
virtualNetworks | array | Array of objects to create VNETs in Subscriptions.

Example of existingSubscriptions object:
```
{
    mg: 'Management Group Name'
    id: 'Subscription ID'
}
```

Example of rbacAssignments object:
```
{
  mg: 'Management Group Name'
  roleId: 'Azure Role Definition ID'
  objectId: 'AAD ObjectID'
  name: 'Name for Assignment'
}
```

Example of virtualNetworks object:
```
{
    name: 'vnet name prefix, example: name: 'prod' and region was eastus would deploy a vnet named 'prod-eastus-vnet'
    subId: 'Subscription ID that VNET will be deployed in'
    vnetAddressSpace: 'Cider range for VNET Example: 10.0.0.0/22'
    dnsServers: [] Arrary of DNS Servers. Example: ['10.2.0.2','192.168.1.1']
    type: 'Hub or Spoke, Hub Networks have the option to deploy Gateways'
    location: 'Azure Region'
    resourceGroupName: 'Name of Resource Group that VNET will be deployed in.'
    nsgRules: [] Array of NSG Rules
    routes: [] Array of Routes
    disableBgpRoutePropagation: 'true or false' Sets on deployed Route Table
    subnets: [] Array of subnets
    tags: {} Tags
}
```

Example of virtualNetworks/subnets object:
```
{
    name: 'Subnet Name'
    addressPrefix: 'Cider for Subnet'
    nsg: true or false 'Apply NSG to subnet True or False'
    routeTable: true or false 'Apply RouteTable to subnet True or False'
}
```

Example of virtualNetworks/gateways object:
```
{
    name: 'vpn' Name of VPN Gateway
    size: 'Basic' VPN Gateway Size
    type: 'Vpn' VPN or ExpressRoute
}
```

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
         rbacAssignments: [
             {
                mg: 'Finance'
                roleId: 'acdd72a7-3385-48ef-bd42-f606fba81ae7'
                objectId: 'AAD ObjectID'
                name: 'Finance Readers'
            }
         ]
         virtualNetworks: [
            {
                name: 'prod'
                subId: 'xxx-xxxxx-xxxx-xxxx'
                vnetAddressSpace: '10.0.0.0/22'
                dnsServers: ['10.2.0.2','192.168.1.1']
                type: 'spoke'
                location: 'eastus'
                resourceGroupName: 'prod-vnet-eastus'
                nsgRules: []
                routes: []
                disableBgpRoutePropagation: false
                subnets: [
                    {
                        name: 'test1'
                        addressPrefix: '10.0.0.0/24'
                        nsg: true
                        routeTable: false
                    }
                    {
                        name: 'test2'
                        addressPrefix: '10.0.1.0/24'
                        nsg: true
                        routeTable: true
                    }
                ] 
                tags: {
                    Spoke:'SpokeVNET'
                }
            }
            {
                name: 'hub'
                subId: 'xxx-xxxxx-xxxx-xxxx'
                vnetAddressSpace: '10.0.4.0/22'
                dnsServers: ['10.2.0.2','192.168.1.1']
                type: 'hub'
                location: 'eastus'
                resourceGroupName: 'hub-vnet-eastus'
                nsgRules: []
                routes: []
                disableBgpRoutePropagation: false
                subnets: [
                    {
                        name: 'test1'
                        addressPrefix: '10.0.4.0/24'
                        nsg: true
                        routeTable: false
                    }
                    {
                        name: 'GatewaySubnet'
                        addressPrefix: '10.0.7.224/27'
                        nsg: false
                        routeTable: false
                    }
                ]
                gateways: [
                    {
                        name: 'hubGw-vpn'
                        size: 'Basic'
                        type: 'Vpn'
                    },
                    {
                        name: 'hubGw-Er'
                        size: 'Standard'
                        type: 'ExpressRoute'
                    } 
                ] 
                tags: {
                }
            }
         ] 
      }
  }
}
```