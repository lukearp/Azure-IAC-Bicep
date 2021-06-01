param name string
param location string = resourceGroup().location
param vnetId string
param subnetName string
param dnsServers array
param loadBalancerConfig array
param enableAcceleratedNetworking bool
param ipConfigurations array

resource nic 'Microsoft.Network/networkInterfaces@2020-11-01' = {
  name: name
  location: location
  properties: {
    dnsSettings: {
      dnsServers: dnsServers  
    }
    enableAcceleratedNetworking: enableAcceleratedNetworking
    enableIPForwarding: false
    ipConfigurations: ipConfigurations      
  }   
}
