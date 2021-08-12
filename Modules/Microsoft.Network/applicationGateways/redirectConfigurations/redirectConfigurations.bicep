param name string
@allowed([
  'Permanent'
  'Found'
  'SeeOther'
  'Temporary'
])
param redirectType string
param targetListenerId string
param targetUrl string
param includePath bool
param includeQueryString bool
//param requestRoutingRules array = []
//param urlPathMaps array = []
//param pathRules array = []

var redirectConfig = {
  name: name
  properties: {
    redirectType: redirectType
    targetListener: {
      id: targetListenerId
    }
    targetUrl: targetUrl
    includePath: includePath
    includeQueryString: includeQueryString
  }
}

output redirectConfiguration object = redirectConfig
