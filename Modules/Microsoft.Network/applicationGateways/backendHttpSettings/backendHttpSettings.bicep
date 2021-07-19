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
param affinityCookieName string
@minValue(1)
@maxValue(86400)
param requestTimeout int = 20
param probeId string
param authenticationCertificateIDs array = []
param trustedRootCertificateIDs array = []
param connectionDrainEnabled bool = false
@minValue(1)
@maxValue(3600)
param connectionDrainTimeout int = 0
param hostName string
param pickHostNameFromBackendAddress bool
param probeEnabled bool = false
param path string

var authenticationCertificates = [for cert in authenticationCertificateIDs: {
  id: cert
}]

var trustedRootCertificates = [for cert in trustedRootCertificateIDs: {
  id: cert
}]

var properties = probeId != '' && cookieBasedAffinity != 'Enabled' ? {
  port: port
  protocol: protocol
  cookieBasedAffinity: cookieBasedAffinity
  requestTimeout: requestTimeout
  probe: {
    id: probeId
  }
  authenticationCertificates: authenticationCertificates
  trustedRootCertificates: trustedRootCertificates
  connectionDraining: {
    enabled: connectionDrainEnabled
    drainTimeoutInSec: connectionDrainTimeout
  }
  hostName: hostName
  pickHostNameFromBackendAddress: pickHostNameFromBackendAddress
  probeEnabled: probeEnabled
  path: path
} : probeId != '' && cookieBasedAffinity != 'Disabled' ? {
  port: port
  protocol: protocol
  cookieBasedAffinity: cookieBasedAffinity
  requestTimeout: requestTimeout
  probe: {
    id: probeId
  }
  authenticationCertificates: authenticationCertificates
  trustedRootCertificates: trustedRootCertificates
  connectionDraining: {
    enabled: connectionDrainEnabled
    drainTimeoutInSec: connectionDrainTimeout
  }
  hostName: hostName
  pickHostNameFromBackendAddress: pickHostNameFromBackendAddress
  affinityCookieName: affinityCookieName
  probeEnabled: probeEnabled
  path: path
} : probeId == '' && cookieBasedAffinity != 'Enabled' ? {
  port: port
  protocol: protocol
  cookieBasedAffinity: cookieBasedAffinity
  requestTimeout: requestTimeout
  authenticationCertificates: authenticationCertificates
  trustedRootCertificates: trustedRootCertificates
  connectionDraining: {
    enabled: connectionDrainEnabled
    drainTimeoutInSec: connectionDrainTimeout
  }
  hostName: hostName
  pickHostNameFromBackendAddress: pickHostNameFromBackendAddress
  probeEnabled: probeEnabled
  path: path
} : {
  port: port
  protocol: protocol
  cookieBasedAffinity: cookieBasedAffinity
  requestTimeout: requestTimeout
  authenticationCertificates: authenticationCertificates
  trustedRootCertificates: trustedRootCertificates
  connectionDraining: {
    enabled: connectionDrainEnabled
    drainTimeoutInSec: connectionDrainTimeout
  }
  hostName: hostName
  pickHostNameFromBackendAddress: pickHostNameFromBackendAddress
  affinityCookieName: affinityCookieName
  probeEnabled: probeEnabled
  path: path
}

var httpSetting = {
  name: name
  properties: properties
}
