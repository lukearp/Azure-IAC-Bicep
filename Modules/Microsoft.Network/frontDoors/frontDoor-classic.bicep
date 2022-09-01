param name string
param friendlyName string
param location string
@metadata({
  description: 'https://docs.microsoft.com/en-us/azure/templates/microsoft.network/frontdoors?tabs=bicep#backendpool' 
})
param backendPools array
@allowed([
  'Disabled'
  'Enabled'
])
param enforceCertificateNameCheckBackendPools string = 'Enabled'
param backendTimeoutSeconds int
@metadata({
  description: 'https://docs.microsoft.com/en-us/azure/templates/microsoft.network/frontdoors?tabs=bicep#frontendendpoint' 
})
param frontendEndpoints array
@metadata({
  description: 'https://docs.microsoft.com/en-us/azure/templates/microsoft.network/frontdoors?tabs=bicep#healthprobesettingsmodel' 
})
param healthProbeSettings array
@metadata({
  description: 'https://docs.microsoft.com/en-us/azure/templates/microsoft.network/frontdoors?tabs=bicep#loadbalancingsettingsmodel' 
})
param loadBalancingSettings array
@metadata({
  description: 'https://docs.microsoft.com/en-us/azure/templates/microsoft.network/frontdoors?tabs=bicep#routingrule' 
})
param routingRules array

resource fd 'Microsoft.Network/frontDoors@2020-05-01' = {
  name: name
  location: location
  properties: {
    backendPools: backendPools
    friendlyName: friendlyName
    backendPoolsSettings: {
      enforceCertificateNameCheck: enforceCertificateNameCheckBackendPools
      sendRecvTimeoutSeconds: backendTimeoutSeconds  
    }
    enabledState: 'Enabled'     
    frontendEndpoints: frontendEndpoints
    healthProbeSettings: healthProbeSettings
    loadBalancingSettings: loadBalancingSettings
    routingRules: routingRules             
  }  
}

resource customHttpsConfiguration 'Microsoft.Network/frontDoors/frontendEndpoints/customHttpsConfiguration@2020-07-01' = [for frontEnd in frontendEndpoints : {
  name: '${name}/${frontEnd.name}/default'
  dependsOn: [
    fd
  ]
  properties: {
    protocolType: 'ServerNameIndication'
    certificateSource: 'FrontDoor'
    frontDoorCertificateSourceParameters: {
      certificateType: 'Dedicated'
    }
    minimumTlsVersion: '1.2'
  }
}]
