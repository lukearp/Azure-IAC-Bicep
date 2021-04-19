param vnetName string
param vnetAddressSpaces array
param vnetDnsServers array
param vnetSubnets array
param location string = resourceGroup().location

resource vnet 'Microsoft.Network/virtualNetworks@2020-11-01' = {
  name: vnetName
  location: location
  properties:{
    addressSpace: {
      addressPrefixes: vnetAddressSpaces
    }
    dhcpOptions:{
      dnsServers: vnetDnsServers
    }
    subnets: [for subnet in vnetSubnets: {
       name: subnet.name
       properties:{
         addressPrefix: subnet.addressPrefix
         networkSecurityGroup:{
           id: '${resourceGroup().id}/providers/Microsoft.Network/networkSecurityGroups/${subnet.networkSecurityGroup}' 
         }
         routeTable: {
            id: '${resourceGroup().id}/providers/Microsoft.Network/routeTables/${subnet.routeTable}'  
         }          
       }           
    }]
  }
}
