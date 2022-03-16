param name string
param location string
param tags object
@allowed([
  'External'
  'Internal'
])
param type string
param pipId string = ''
param subnetId string = ''
param staticIp string

var frontEndProperties = type == 'External' ? {
  publicIPAddress: {
    id: pipId  
  }
}:{
  privateIPAddressVersion: 'IPv4'
  privateIPAllocationMethod: staticIp == '' ? 'Dynamic' : 'Static'
  privateIpAddress: staticIp 
  subnet: {
    id: subnetId  
  }
}

resource lb 'Microsoft.Network/loadBalancers@2021-05-01' = {
  name: name
  location: location
  tags: tags  
  sku: {
    name: 'Standard'
    tier: 'Regional'  
  } 
  properties: {
    frontendIPConfigurations: [
      {
        name: 'frontend'
        properties: frontEndProperties
        zones: [
          '1'
          '2'
          '3'
        ] 
      }  
    ]
    backendAddressPools: [
      {
        name: 'logForwarders'
        properties: {  
        }  
      } 
    ]
    probes: [
      {
        name: 'health'
        properties: {
          port: 514
          protocol: 'Tcp'
          intervalInSeconds: 5
          numberOfProbes: 2    
        }  
      } 
    ]
    loadBalancingRules: [
      {
        name: 'Syslog-HA-Port'
        properties: {
          frontendIPConfiguration: {
            id: '${resourceId('Microsoft.Network/loadBalancers',name)}/frontendIPConfigurations/frontend'
          }
          frontendPort: 0
          backendPort: 0
          enableFloatingIP: false
          protocol: 'All'
          idleTimeoutInMinutes: 4
          disableOutboundSnat: false
          backendAddressPool: {
            id: '${resourceId('Microsoft.Network/loadBalancers',name)}/backendAddressPools/logForwarders'
          }
          probe: {
            id: '${resourceId('Microsoft.Network/loadBalancers',name)}/probes/health'
          } 
        } 
      }
    ]   
  } 
}

output backendPoolId string = '${resourceId('Microsoft.Network/loadBalancers',name)}/backendAddressPools/logForwarders'
