# What does this module do?
Creates a Stanadrd Tier Logic app.  You will have the option for deploying with Private Link and VNET Integration.  When Private Link endpoints are deployed, Azure Private DNS Zones will either be created or A Records will be created in existing Private DNS Zones to resolve the private endpoints.  

# What does this module Require?
Depending on your deployment options, you would need Azure Website Contributor on a Resource Group.  If you select to enable VNET Integration you will need a Subnet ID to configure the integration.  If you select to deploy Private Link, you will need a Subnet ID for the Private Link endpoints deployed.  Both of the VNET tasks require subnets/join permissions on the Virtual Network.     

# Parameters
param | type | notes
------|------|------
name | string | Name of Logic App
location | string | Azure region to deploy logic app.
azureGov | bool | False = Azure Commercial Data Center, True = Azure Government Data Center. Default Value is false
existingAppServicePlan | bool | False = Deploy a new App Service Plan, True = Use existing app service plan.  Default Value is false
existingAppServicePlanId | string | Resource ID of existing App Service plan.  Only used if existingAppServicePlan = true
appPlanSize | string | Size of App Service Plan.  Default is WS1
aseId | string | Resource ID of App Service Environment.  Default value is ''.  Only use if deploying Logic App to App Service Environment
enableVNETIntegration | bool | False = No VNET Integration Enabled, True = Associate outbound traffic to Virtual Network Subnet. Default Value is false
logicAppVNETSubnetId | string | Resource ID of VNET Integration Subnet.  Only used if enableVNETIntegration = true
enablePrivateLink | bool | False = No private Link Endpoints created, True = private link endpoints deployed on Logic App and Storage Account. Default Value is false
publicNetworkAccessEnabled | bool | False = No public access enabled for service.  enablePrivateLink must equal true, True = Public access to Logic app and Storage is enabled. Default Value is true
privateLinkSubnetId | string | Resource ID of subnet for private link endpoints.
dnsZoneRg | string | Name of resource group for Azure Private DNS Zones
dnsZoneSubscriptionId | string | Azure Subscription that has the Azure Private DNS Zones
associateDnsZonesWithVNET | bool | False = The private link DNS Zones will not be associated to a Virtual Network, True = the private link DNS Zones will be assocated to a virtual network. Default Value is false
dnsVnetId | string | Virtual Network Resource ID to associate the Private Link DNS Zones to.  associateDnsZonesWithVNET must equal true.
tags | object | Resource tags  

# Sample Module

```Bicep
targetScope = 'subscription'

resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: 'standard-lg-deploy'
  location: 'eastus'
}

module deploy '../Standard-Deployments/LogicApp-Standard/LogicApp-Standard.bicep' = {
  name: 'My-Deploy' 
  scope: resourceGroup(rg.name) 
  params: {
    location: 'eastus'
    name: 'lukelogictest'
    azureGov: false
    associateDnsZonesWithVNET: false
    dnsZoneRg: 'core-workloads-networking-eastus-rg'
    dnsZoneSubscriptionId: 'XXXXXXX-4029-4094-85e3-XXXXXXXX'
    enablePrivateLink: true
    enableVNETIntegration: true
    logicAppVNETSubnetId: '/subscriptions/XXXXXXX-4029-4094-85e3-XXXXXXXX/resourceGroups/core-workloads-networking-eastus-rg/providers/Microsoft.Network/virtualNetworks/core-workloads-eastus-vnet/subnets/LogicApp-Subnet2'
    privateLinkSubnetId: '/subscriptions/XXXXXXX-4029-4094-85e3-XXXXXXXX/resourceGroups/core-workloads-networking-eastus-rg/providers/Microsoft.Network/virtualNetworks/core-workloads-eastus-vnet/subnets/VDI'       
    tags: {
      Test: 'Deployment'
    }     
  } 
}
```