# What does this module do?
Creates Management Group Hierarchy per [CAF Guidance](https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone/design-area/resource-org-management-groups). 

## Update:
I recently updated the deployment to leverage my VPN Gateway Module.  This has allowed me to set more gateway specific configurations.  If you have already deployed with the old deployment, the new version will most likely fail due to the ipconfig name on your gateway changing.  The original deployment using ipconfig, but the new using ipconfig1 or ipconfig2 depending if activeActive is set to true.  If this is an issue, you can change the virtualNetworkGateway.bicep module to use ipconfig in your fork. 

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
policyAssignments | array | Array of objects to assign Policy to deployed Management Groups.
virtualNetworks | array | Array of objects to create VNETs in Subscriptions.
defaultLocation | string | Default Azure Region for certain deployments.  default = 'eastus'

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

Example of policyAssignments object: 
```
policyAssignments Object =
{
  name: 'Name of Assignment'
  policyId: 'PolicyId'
  parameters: { Parameters to pass to the policy you are assigning
    param: {
      value: 'param'
    }
  }
  notScopes: [
    'resourceIds' scopes to exclude from policy
  ]
  mg: 'MG Id' Target Management Group
}
```

Example of virtualNetworks object:
```
{
    name: 'vnet name'
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

Example of virtualNetworks/gateways object (For ER Gateways, still set a value for ASN and Active Active, but they will be ignored on deployment):
```
{
    name: 'Core-VPN'
    size: 'VpnGw1'
    type: 'Vpn'
    activeActive: true
    asn: 65000
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
         policyAssignments: [
             {
                name: 'Enterprise-Initiative'
                policyId: '/providers/Microsoft.Management/managementGroups/luke-test/providers/Microsoft.Authorization/policySetDefinitions/Policy-1'
                parameters: {
                    allowedRegions: {
                        value: [
                            'eastus'
                            'westus'
                        ]
                    }
                }
                notScopes: []
                mg: 'luke-test'
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
                        name: 'Core-VPN'
                        size: 'VpnGw1'
                        type: 'Vpn'
                        activeActive: true
                        asn: 65000
                    }
                    {
                        name: 'Core-ER'
                        size: 'Standard'
                        type: 'ExpressRoute'
                        activeActive: false
                        asn: 65515
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