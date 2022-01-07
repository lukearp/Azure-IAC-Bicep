param vnetName string
param location string
param subnets array
param addressSpace array
param dnsServers array
param hubVnetId string
param nvaIp string
param hubAddressSpace string
param gatewayRtId string

var routes = [
  {
    properties: {
      addressPrefix: hubAddressSpace
      nextHopType: 'VirtualAppliance'
      nextHopIpAddress: nvaIp  
    }
    name: 'HUB-Address-Space' 
  }
  {
    properties: {
      addressPrefix: '0.0.0.0/0'
      nextHopType: 'VirtualAppliance'
      nextHopIpAddress: nvaIp  
    }
    name: 'Default-Route' 
  }
]

resource rt 'Microsoft.Network/routeTables@2021-02-01' = {
  name: 'RT_${location}'
  location: location
  properties: {
    routes: routes
    disableBgpRoutePropagation: location == 'eastus' ? true : false 
  }  
}

resource nsg 'Microsoft.Network/networkSecurityGroups@2021-02-01' = {
  name: 'Default-NSG'
  location: location
  properties: {
    
  }   
}

var addRoutes = [for subnet in subnets: subnet.name != 'GatewaySubnet' ? union({
  properties: {
    routeTable: {
      id: rt.id
    }
  }
},subnet): union({},subnet)]

var addNsgs = [for subnet in addRoutes: subnet.name != 'GatewaySubnet' ? union({
  properties: {
    networkSecurityGroup: {
      id: nsg.id
    }
  }
},subnet) : union({},subnet)]

resource vnet 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: addressSpace 
    }
    subnets: addNsgs
    dhcpOptions: {
      dnsServers: dnsServers  
    }     
  }  
}

resource spokePeer 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-02-01' = {
  name: 'To-HUB'
  parent: vnet
  properties: {
    allowForwardedTraffic: true
    allowGatewayTransit: false
    allowVirtualNetworkAccess: true
    useRemoteGateways: true
    remoteVirtualNetwork: {
      id: hubVnetId 
    }     
  }   
}

module hubPeer 'hubPeer.bicep' = {
  name: 'Peer-Hub'
  dependsOn: [
    spokePeer
  ]
  scope: resourceGroup(split(hubVnetId,'/')[2],split(hubVnetId,'/')[4])
  params: {
    hubVnetId: hubVnetId
    spokeVnetId: vnet.id 
  }  
}

module remoteRtAdd 'remoteRtAdd.bicep' = {
  name: 'Gateway-RT'
  scope: resourceGroup(split(gatewayRtId,'/')[2],split(gatewayRtId,'/')[4])  
  params: {
    gatewayRtId: gatewayRtId
    nextHopType: 'VirtualAppliance' 
    nvaIp: nvaIp
    vnetAddressSpace: addressSpace
    vnetName: vnetName      
  } 
}
