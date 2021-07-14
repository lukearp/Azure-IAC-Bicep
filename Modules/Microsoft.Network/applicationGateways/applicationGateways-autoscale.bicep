param name string
param location string = resourceGroup().location
param tags object = {}
param useZones bool = true
param zones array = []
param autoScaleMin int = 0
param autoScaleMax int
param backendPools array
param backendHttpSettings array
param frontEndIpConfigs array
param frontEndPorts array
param httpListeners array
param sslCertificates array
param redirectConfigurations array
param requestRoutingRules array
param rewriteRuleSets array
param healthProbes array
param urlPathMaps array
param enableFips bool
param enableHttp2 bool
@allowed([
  'WAF_v2'
  'Standard_v2'
])
param skuName string

var azRegions = [
  'eastus'
  'eastus2'
  'centralus'
  'southcentralus'
  'usgovvirginia'
  'westus2'
  'westus3'
]

var zoneArray = useZones == true && contains(azRegions, location) ? zones == [] ? [
  '1'
  '2'
  '3'
] : zones : []

resource appGateway 'Microsoft.Network/applicationGateways@2021-02-01' = {
  location: location 
  name: name
  zones: zoneArray
  properties: {
    autoscaleConfiguration: {
       maxCapacity: autoScaleMax
       minCapacity: autoScaleMin  
    }
    backendAddressPools: backendPools
    backendHttpSettingsCollection: backendHttpSettings
    enableFips: enableFips
    enableHttp2: enableHttp2
    frontendIPConfigurations: frontEndIpConfigs
    frontendPorts: frontEndPorts
    httpListeners: httpListeners
    probes: healthProbes
    sku: {
      name: skuName
      tier: skuName  
    }
    sslCertificates: sslCertificates  
    urlPathMaps: urlPathMaps 
    redirectConfigurations: redirectConfigurations
    requestRoutingRules: requestRoutingRules
    rewriteRuleSets: rewriteRuleSets          
  } 
  tags: tags 
}
