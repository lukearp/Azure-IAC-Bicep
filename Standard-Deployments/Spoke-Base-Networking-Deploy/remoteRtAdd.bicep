param nvaIp string
param vnetAddressSpace array
param nextHopType string
param vnetName string
param gatewayRtId string

resource rt 'Microsoft.Network/routeTables@2021-02-01' existing = {
  name: split(gatewayRtId,'/')[8] 
}

resource route 'Microsoft.Network/routeTables/routes@2021-02-01' = [for (addressSpace,i) in vnetAddressSpace: {
  name: 'To-${vnetName}-${i}'
  parent: rt
  properties: {
    addressPrefix: addressSpace
    nextHopIpAddress: nvaIp
    nextHopType: nextHopType  
  }  
}]
