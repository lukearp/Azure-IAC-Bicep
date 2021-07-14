param name string
param port int
@allowed([
  'Http'
  'Https'
])
param protocol string
@allowed([
  'Enabled'
  'Disabled'
])
param cookieBasedAffinity string
@minValue(1)
@maxValue(86400)
param requestTimeout int
param probeId string
param authenticationCertificateIDs array
param trustedRootCertificateIDs array
param connectionDrainEnabled bool = false
@minValue(1)
@maxValue(3600)
param connectionDrainTimeout int
param hostName string
param pickHostNameFromBackendAddress bool
param probeEnabled bool = false
param path string 
