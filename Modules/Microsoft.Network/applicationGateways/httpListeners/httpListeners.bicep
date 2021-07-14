param name string
param frontendIPConfiguration object
param frontendPort object
@allowed([
  'Http'
  'Https'
])
param protocol string
param hostName string
param hostNames array = []
param sslCertificateId string
param sslProfileId string
param requireServerNameIndication bool
param firewallPolicyId string

var properties = protocol == 'Https' ? {
  frontendIPConfiguration: frontendIPConfiguration
  frontendPort: frontendPort
  protocol: protocol
  hostName: hostName
  sslCertificate: {
    id: sslCertificateId
  }
  sslProfile: {
    id: sslProfileId
  }
  requireServerNameIndication: requireServerNameIndication
  firewallPolicy: {
    id: firewallPolicyId
  }
  hostNames: hostNames
} : {
  frontendIPConfiguration: frontendIPConfiguration
  frontendPort: frontendPort
  protocol: protocol
  hostName: hostName
  firewallPolicy: {
    id: firewallPolicyId
  }
  hostNames: hostNames
}

var httpListener = {
  name: name
  properties: properties
}

output httpListenerObj object = httpListener
