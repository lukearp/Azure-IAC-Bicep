targetScope = 'subscription'
param NamePrefix string
param location string
param NetworkAddressPrefix string

resource group 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: '${NamePrefix}-VN-rg'
  location: location
  properties: {} 
}

module vnet '../../Modules/Microsoft.Network/virtualNetworks/virtualNetworks-simple.bicep' = {
  name: '${NamePrefix}-VN-01-Deploy'
  scope: resourceGroup(group.name)
  params: {
    location: location
    addressSpacePrefixes: [
      NetworkAddressPrefix
    ] 
    dnsServers: []
    name: '${NamePrefix}-VN-01'
    subnets: []     
  } 
}

module nsg '../../Modules/Microsoft.Network/networkSecurityGroups/networkSecurityGroups.bicep' = {
  name: '${NamePrefix}-PL-NSG-Deploy'
  scope: resourceGroup(group.name)
  params: {
    location: location
    nsgs: [
      {
        name: '${NamePrefix}-PL-NSG'
      }
    ]  
  } 
}

module privateLinkSubnet '../../Modules/Microsoft.Network/virtualNetworks/subnets/subnets.bicep' = {
  name: '${NamePrefix}-PL-SN-Deploy' 
  scope: resourceGroup(group.name)
  params: {
    subnetName: '${NamePrefix}-PL-SN'
    addressPrefix: '192.168.0.0/26'
    vnetname: split(vnet.outputs.resourceId,'/')[8] 
    nsgName: split(nsg.outputs.nsgIds[0].id,'/')[8]  
  } 
}

output vnetId string = vnet.outputs.resourceId
output privateLinkSubnetId string = privateLinkSubnet.outputs.subnetId
