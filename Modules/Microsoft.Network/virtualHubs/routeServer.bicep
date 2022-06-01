param routeServerName string
param location string
param tags object = {}
param vnetId string
param allowBranchToBranchTraffic bool = false

resource routeServer 'Microsoft.Network/virtualHubs@2021-08-01' = {
  name: routeServerName
  location: location
  tags: tags
  properties: {
    sku: 'Standard'
    allowBranchToBranchTraffic: allowBranchToBranchTraffic 
  }    
}

module pip '../publicIpAddresses/publicIpAddresses.bicep' = {
  name: '${routeServerName}-PIP-Deploy'
  params: {
    name: '${routeServerName}-pip'
    publicIpAddressVersion: 'IPv4'
    publicIpAllocationMethod: 'Static' 
    sku: 'Standard'
    tier: 'Regional'
    location: location     
  }  
}

resource ipconfig 'Microsoft.Network/virtualHubs/ipConfigurations@2021-08-01' = {
  name: '${routeServerName}-config' 
  parent: routeServer  
  properties: {
     subnet: {
       id: '${vnetId}/subnets/RouteServerSubnet' 
     } 
     privateIPAllocationMethod: 'Dynamic'
     publicIPAddress: {
       id: pip.outputs.pipid 
     }   
  }  
}
