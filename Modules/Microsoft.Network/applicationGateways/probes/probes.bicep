param name string
@allowed([
  'Http'
  'Https'
])
param protocol string
@description('Host name to send the probe to.')
param host string
param path string
@minValue(1)
@maxValue(86400)
param interval int
@minValue(1)
@maxValue(86400)
param timeout int
@minValue(1)
@maxValue(20)
param unhealthyThreshold int
param pickHostNameFromBackendHttpSettings bool
@description('Minimum number of servers that are always marked healthy. Default value is 0.')
param minServers int = 0
@minValue(1)
@maxValue(65535)
param port int
param matchBody string = ''
param matchStatus array

var match = matchBody == '' ? {
  statusCodes: matchStatus
} : {
  body: matchBody
  statusCodes: matchStatus
}

var probe = {
  name: name
  properties: {
    protocol: protocol
    host: host
    path: path
    interval: interval
    timeout: timeout
    unhealthyThreshold: unhealthyThreshold
    pickHostNameFromBackendHttpSettings: pickHostNameFromBackendHttpSettings
    minServers: minServers
    match: match
    port: port
  }
}

output probeObj object = probe
