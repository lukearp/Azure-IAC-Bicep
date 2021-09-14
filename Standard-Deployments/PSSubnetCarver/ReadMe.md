# What does this module do?
Leverages the PSSubnetCarver PS Module to automatically subnet my IPv4 address space.  It does this by leveraging Microsoft.Resources/deploymentScripts .

# Dependencies
* The Deployment Script Module in Modules/Microsoft.Resources/deploymentScripts/deploymentScripts-powershell.bicep
* The PSScript in Scripts/VNET-IP-Segmentation/VNET-AddressSpace-Carve-DeploymentScript.ps1

# Parameters
param | type | notes
------|------|------
subscriptionName | string | Name to represent the Subscription.  Used to build the Context
subnets | array | Array of Subnet objects in the following format
vnetAddressSpaces | array | Array of VNET Address spaces the Subnets will be carved from
userManagedIdentityId | string | Resource ID Of Usermanaged Identity that has rights to create a deployment script in the deployment scope.

Subnet Object breakdown
```dotnetcli
{
    cidr: bool
    addressSize: int
    name: string
}
```
property | notes
--------- | ------
cider | Signifies if the addressSize property is a CIDR value or Host Count.  If a CIDR is true, PSSubnetCarver attempts to reserve that CIDR.  If CIDR is false, it will reserve a CIDR based on if it can accomidate that many hosts.  Example: cider: true and addressSize: 24 would reserve X.X.X.X/24, but cider: false and addressSize 24 would reserve X.X.X.X/27.
name | Name of the subnet

# Example

## Module reference
```
var subnets = [
  {
    cidr: true
    addressSize: 24
    name: 'management'
  }
  {
    cidr: true
    addressSize: 24
    name: 'vm'
  }
  {
    cidr: false
    addressSize: 160
    name: 'dev'
  }
]

var subscription = 'myProdSub'
var vnetAddressSpaces = [
  '10.20.0.0/17'
]

module deploymentScript '../Standard-Deployments/PSSubnetCarver/psSubnetCarver.bicep' = {
  name: 'IPCarveTest-1'
  params: {
    userManagedIdentityId: '/subscriptions/XXXX-XXX-XXXXX-XXXXXX/resourceGroups/user-identities/providers/Microsoft.ManagedIdentity/userAssignedIdentities/template-spec'
    subnets: subnets
    subscriptionName: subscription
    vnetAddressSpaces: vnetAddressSpaces        
  } 
}

output subnets array = deploymentScript.outputs.carvedSubnets 
```

## Module Output
```dotnetcli
DeploymentName          : Test
ResourceGroupName       : bicep_palo
ProvisioningState       : Succeeded
Timestamp               : 9/14/2021 1:09:40 PM
Mode                    : Incremental
TemplateLink            :
Parameters              :
Outputs                 :
                          Name             Type                       Value
                          ===============  =========================  ==========
                          subnets              Array                      [
                            {
                              "cidr": true,
                              "addressSize": 24,
                              "name": "management",
                              "AddressSpaceReserved": "10.20.0.0/24"
                            },
                            {
                              "cidr": true,
                              "addressSize": 24,
                              "name": "vm",
                              "AddressSpaceReserved": "10.20.1.0/24"
                            },
                            {
                              "cidr": false,
                              "addressSize": 160,
                              "name": "dev",
                              "AddressSpaceReserved": "10.20.2.0/24"
                            }
                          ]

DeploymentDebugLogLevel :
```