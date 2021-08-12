param name string
@allowed([
  'Basic'
  'PathBasedRouting'
])
param ruleType string
param priority int
param backendAddressPoolId string
param backendHttpSettingsId string
param httpListenerId string
param urlPathMapId string = ''
param rewriteRulesetId string = ''
param redirectConfigurationId string = ''

var reqRouting = {
  name: name
  properties: {
    ruleType: ruleType
    priority: priority
    backendAddressPool: {
      id: backendAddressPoolId
    }
    backendHttpSettings: {
      id: backendHttpSettingsId
    }
    httpListener: {
      id: httpListenerId
    }
    urlPathMap: {
      id: urlPathMapId
    }
    rewriteRuleSet: {
      id: rewriteRulesetId
    }
    redirectConfiguration: {
      id: redirectConfigurationId
    }
  }
}

output requestRoutingRule object = reqRouting
