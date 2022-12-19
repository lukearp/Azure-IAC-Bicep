targetScope = 'subscription'

var region = 'eastus'
var tags = {}

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  location: region
  name: 'firewall-policies' 
  properties: {}
  tags: tags   
}
module ParentPolicy '../../../../../Modules/Microsoft.Network/firewallPolicies/firewallPolicies.bicep' = {
  name: 'Parent-Policy'
  scope: resourceGroup(rg.name)
  params: {
   location: region
   name: 'Parent-Policy'
   firewallTier: 'Premium'
   tags: tags       
  }   
}

module Child '../../../../../Modules/Microsoft.Network/firewallPolicies/firewallPolicies.bicep' = {
  name: 'Child-Policy'
  scope: resourceGroup(rg.name)
  params: {
   location: region
   name: 'Child-Policy'
   firewallTier: 'Premium'
   tags: tags 
   basePolicy: ParentPolicy.outputs.resourceId      
  }   
}

module firewallSubnet '../../../../../Modules/Microsoft.Network/virtualNetworks/subnets/subnets.bicep' = {
  name: 'AzureFirewallSubnet'
  scope: resourceGroup('core-transit-networking-eastus-rg')  
  params: {
    addressPrefix: '10.0.14.64/26'
    subnetName: 'AzureFirewallSubnet'
    vnetname: 'core-transit-eastus-vnet'    
  } 
}

module firewallPip '../../../../../Modules/Microsoft.Network/publicIpAddresses/publicIpAddresses.bicep' = {
  name: 'Az-FW-${region}-Pip'
  scope: resourceGroup('core-transit-networking-eastus-rg')
  params: {
    name: 'Az-FW-${region}-Pip'
    publicIpAddressVersion: 'IPv4'
    publicIpAllocationMethod: 'Static'
    sku: 'Standard'
    tier: 'Regional'
    location: region 
    zones: [
      1
      2
      3
    ]
    tags: tags        
  } 
}

module firewall '../../../../../Modules/Microsoft.Network/azureFirewalls/azureFirewalls-vnet.bicep' = {
  name: 'Firewall'
  scope: resourceGroup('core-transit-networking-eastus-rg') 
  params: {
    name: 'Az-FW-${region}' 
    policyId: Child.outputs.resourceId
    tier: 'Premium'
    subnetId: firewallSubnet.outputs.subnetId
    pipId: firewallPip.outputs.pipid
    location: region
    tags: tags
    useZones: true
    zones: [
      1
      2
      3
    ]       
  }  
}
