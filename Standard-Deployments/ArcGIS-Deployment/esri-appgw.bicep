param name string
param location string = resourceGroup().location
param virtualnetwork string
param virtualnetworkRg string
param subnetName string
param tags object = {}
param useZones bool = true
param zones array = []
param autoScaleMin int = 0
param autoScaleMax int
param enableHttp2 bool
@allowed([
  'WAF_v2'
  'Standard_v2'
])
param skuName string
param serverNicId string
param portalNicId string
param serverVirtualMachineName string
param portalVirtualMachineName string
@secure()
param publicCertString string
@secure()
param rootCert string
param externalDnsHostName string

var subnetId = resourceId(virtualnetworkRg, 'Microsoft.Network/virtualNetworks/subnets', virtualnetwork, subnetName)
var backendPools = [
  {
    name: 'gisServerBackendPool'
    properties: {
      backendAddresses: [
        {
          fqdn: '${serverVirtualMachineName}.${reference(serverNicId, '2023-04-01', 'FULL').properties.dnsSettings.internalDomainNameSuffix}'
        }
      ]
    }
  }
  {
    name: 'gisPortalBackendPool'
    properties: {
      backendAddresses: [
        {
          fqdn: '${portalVirtualMachineName}.${reference(portalNicId, '2023-04-01', 'FULL').properties.dnsSettings.internalDomainNameSuffix}'
        }
      ]
    }
  }
]
var urlPathMaps = [
  {
    name: 'gisEnterprisePathMap'
    properties: {
      defaultBackendAddressPool: {
        id: concat(subscription().id, '/resourceGroups/', resourceGroup().name, '/providers/Microsoft.Network/applicationGateways/', name, '/backendAddressPools/gisServerBackendPool')
      }
      defaultBackendHttpSettings: {
        id: concat(subscription().id, '/resourceGroups/', resourceGroup().name, '/providers/Microsoft.Network/applicationGateways/', name, '/backendHttpSettingsCollection/gisServerHttpsSetting')
      }
      pathRules: [
        {
          name: 'serverPathRule'
          properties: {
            backendAddressPool: {
              id: concat(subscription().id, '/resourceGroups/', resourceGroup().name, '/providers/Microsoft.Network/applicationGateways/', name, '/backendAddressPools/gisServerBackendPool')
            }
            backendHttpSettings: {
              id: concat(subscription().id, '/resourceGroups/', resourceGroup().name, '/providers/Microsoft.Network/applicationGateways/', name, '/backendHttpSettingsCollection/gisServerHttpsSetting')
            }
            paths: [
              '/server/*'
            ]
            rewriteRuleSet: {
              id: concat(subscription().id, '/resourceGroups/', resourceGroup().name, '/providers/Microsoft.Network/applicationGateways/', name, '/rewriteRuleSets/gisServerRewriteRuleSet')
            }
          }
          type: 'Microsoft.Network/applicationGateways/urlPathMaps/pathRules'
        }
        {
          name: 'portalPathRule'
          properties: {
            backendAddressPool: {
              id: concat(subscription().id, '/resourceGroups/', resourceGroup().name, '/providers/Microsoft.Network/applicationGateways/', name, '/backendAddressPools/gisPortalBackendPool')
            }
            backendHttpSettings: {
              id: concat(subscription().id, '/resourceGroups/', resourceGroup().name, '/providers/Microsoft.Network/applicationGateways/', name, '/backendHttpSettingsCollection/gisPortalHttpsSetting')
            }
            paths: [
              '/portal/*'
              '/portal'
            ]
            rewriteRuleSet: {
              id: concat(subscription().id, '/resourceGroups/', resourceGroup().name, '/providers/Microsoft.Network/applicationGateways/', name, '/rewriteRuleSets/gisPortalRewriteRuleSet')
            }
          }
          type: 'Microsoft.Network/applicationGateways/urlPathMaps/pathRules'
        }
      ]
      requestRoutingRules: [
        {
          id: concat(subscription().id, '/resourceGroups/', resourceGroup().name, '/providers/Microsoft.Network/applicationGateways/', name, '/requestRoutingRules/gisEnterpriseRequestRoutingRule')
        }
      ]
    }
    type: 'Microsoft.Network/applicationGateways/urlPathMaps'
  }
]
var rewriteRuleSets = [
  {
    name: 'gisPortalRewriteRuleSet'
    properties: {
      pathRules: [
        {
          id: '${subscription().id}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/applicationGateways/${name}/urlPathMaps/gisEnterprisePathMap/pathRules/portalPathRule'
        }
      ]
      rewriteRules: [
        {
          actionSet: {
            requestHeaderConfigurations: [
              {
                headerName: 'X-Forwarded-Host'
                headerValue: '{http_req_host}'
              }
            ]
            responseHeaderConfigurations: []
          }
          conditions: []
          name: 'XForwardedHostRewrite'
          ruleSequence: 50
        }
        {
          actionSet: {
            requestHeaderConfigurations: []
            responseHeaderConfigurations: [
              {
                headerName: 'RewriteLocationValue'
                headerValue: '{http_resp_Location_1}://{http_req_host}/portal{http_resp_Location_2}'
              }
              {
                headerName: 'Location'
                headerValue: '{http_resp_Location_1}://{http_req_host}/portal{http_resp_Location_2}'
              }
            ]
          }
          conditions: [
            {
              ignoreCase: true
              negate: false
              pattern: '(https?):\\/\\/[^\\/]+:7443\\/(?:arcgis|portal)(.*)$'
              variable: 'http_resp_Location'
            }
          ]
          name: 'PortalRewrite'
          ruleSequence: 100
        }
      ]
    }
    type: 'Microsoft.Network/applicationGateways/rewriteRuleSets'
  }
  {
    name: 'gisServerRewriteRuleSet'
    properties: {
      pathRules: [
        {
          id: '${subscription().id}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/applicationGateways/${name}/urlPathMaps/gisEnterprisePathMap/pathRules/serverPathRule'
        }
      ]
      rewriteRules: [
        {
          actionSet: {
            requestHeaderConfigurations: [
              {
                headerName: 'X-Forwarded-Host'
                headerValue: '{http_req_host}'
              }
            ]
            responseHeaderConfigurations: []
          }
          conditions: []
          name: 'XForwardedHostRewrite'
          ruleSequence: 50
        }
        {
          actionSet: {
            requestHeaderConfigurations: []
            responseHeaderConfigurations: [
              {
                headerName: 'RewriteLocationValue'
                headerValue: '{http_resp_Location_1}://{http_req_host}/server{http_resp_Location_2}'
              }
              {
                headerName: 'Location'
                headerValue: '{http_resp_Location_1}://{http_req_host}/server{http_resp_Location_2}'
              }
            ]
          }
          conditions: [
            {
              ignoreCase: true
              negate: false
              pattern: '(https?):\\/\\/[^\\/]+:6443\\/(?:arcgis|server)(.*)$'
              variable: 'http_resp_Location'
            }
          ]
          name: 'ServerRewrite'
          ruleSequence: 100
        }
      ]
    }
    type: 'Microsoft.Network/applicationGateways/rewriteRuleSets'
  }
]
var requestRoutingRules= [
  {
    name: 'gisEnterpriseRequestRoutingRule'
    properties: {
      httpListener: {
        id: '${subscription().id}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/applicationGateways/${name}/httpListeners/gisHttpsEnterpriseDeploymentListner'
      }
      priority: 10
      ruleType: 'PathBasedRouting'
      urlPathMap: {
        id: '${subscription().id}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/applicationGateways/${name}/urlPathMaps/gisEnterprisePathMap'
      }
    }
    type: 'Microsoft.Network/applicationGateways/requestRoutingRules'
  }
  {
    name: 'gisHttpToHttpsEnterpriseRequestRoutingRule'
    properties: {
      httpListener: {
        id: '${subscription().id}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/applicationGateways/${name}/httpListeners/gisHttpEnterpriseDeploymentListner'
      }
      priority: 20
      redirectConfiguration: {
        id: '${subscription().id}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/applicationGateways/${name}/redirectConfigurations/gisEnterpriseHttpToHttps'
      }
      ruleType: 'Basic'
    }
    type: 'Microsoft.Network/applicationGateways/requestRoutingRules'
  }
]
var redirectConfigurations = [
  {
    name: 'gisEnterpriseHttpToHttps'
    properties: {
      includePath: true
      includeQueryString: true
      redirectType: 'Permanent'
      requestRoutingRules: [
        {
          id: '${subscription().id}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/applicationGateways/${name}/requestRoutingRules/gisHttpToHttpsEnterpriseRequestRoutingRule'
        }
      ]
      targetListener: {
        id: '${subscription().id}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/applicationGateways/${name}/httpListeners/gisHttpsEnterpriseDeploymentListner'
      }
    }
    type: 'Microsoft.Network/applicationGateways/redirectConfigurations'
  }
]
var healthProbes = [
  {
    name: 'gisServerProbeName'
    properties: {
      backendHttpSettings: [
        {
          id: '${subscription().id}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/applicationGateways/${name}/backendHttpSettingsCollection/gisServerHttpsSetting'
        }
      ]
      interval: 30
      match: {
        statusCodes: [
          '200'
        ]
      }
      minServers: 0
      path: '/arcgis/rest/info/healthcheck'
      pickHostNameFromBackendHttpSettings: true
      protocol: 'Https'
      timeout: 30
      unhealthyThreshold: 3
    }
    type: 'Microsoft.Network/applicationGateways/probes'
  }
  {
    name: 'gisPortalProbeName'
    properties: {
      backendHttpSettings: [
        {
          id: '${subscription().id}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/applicationGateways/${name}/backendHttpSettingsCollection/gisPortalHttpsSetting'
        }
      ]
      interval: 30
      match: {
        statusCodes: [
          '200'
        ]
      }
      minServers: 0
      path: '/arcgis/portaladmin/healthCheck'
      pickHostNameFromBackendHttpSettings: true
      protocol: 'Https'
      timeout: 30
      unhealthyThreshold: 3
    }
    type: 'Microsoft.Network/applicationGateways/probes'
  }
]
var frontEndPorts = [
  {
    name: 'gisEnterprisePort443'
    properties: {
      httpListeners: [
        {
          id: '${subscription().id}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/applicationGateways/${name}/httpListeners/gisHttpsEnterpriseDeploymentListner'
        }
      ]
      port: 443
    }
    type: 'Microsoft.Network/applicationGateways/frontendPorts'
  }
  {
    name: 'gisEnterprisePort80'
    properties: {
      httpListeners: [
        {
          id: '${subscription().id}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/applicationGateways/${name}/httpListeners/gisHttpEnterpriseDeploymentListner'
        }
      ]
      port: 80
    }
    type: 'Microsoft.Network/applicationGateways/frontendPorts'
  }
]
var httpListeners = [
  {
    name: 'gisHttpEnterpriseDeploymentListner'
    properties: {
      enableHttp3: false
      frontendIPConfiguration: {
        id: '${subscription().id}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/applicationGateways/${name}/frontendIPConfigurations/gisEnterpriseAppGatewayFrontendIP'
      }
      frontendPort: {
        id: '${subscription().id}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/applicationGateways/${name}/frontendPorts/gisEnterprisePort80'
      }
      hostNames: [
        externalDnsHostName
      ]
      protocol: 'Http'
      requestRoutingRules: [
        {
          id: '${subscription().id}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/applicationGateways/${name}/requestRoutingRules/gisHttpToHttpsEnterpriseRequestRoutingRule'
        }
      ]
      requireServerNameIndication: false
    }
    type: 'Microsoft.Network/applicationGateways/httpListeners'
  }
  {
    name: 'gisHttpsEnterpriseDeploymentListner'
    properties: {
      enableHttp3: false
      frontendIPConfiguration: {
        id: '${subscription().id}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/applicationGateways/${name}/frontendIPConfigurations/gisEnterpriseAppGatewayFrontendIP'
      }
      frontendPort: {
        id: '${subscription().id}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/applicationGateways/${name}/frontendPorts/gisEnterprisePort443'
      }
      hostNames: [
        externalDnsHostName
      ]
      protocol: 'Https'
      redirectConfiguration: [
        {
          id: '${subscription().id}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/applicationGateways/${name}/redirectConfigurations/gisEnterpriseHttpToHttps'
        }
      ]
      requestRoutingRules: [
        {
          id: '${subscription().id}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/applicationGateways/${name}/requestRoutingRules/gisEnterpriseRequestRoutingRule'
        }
      ]
      requireServerNameIndication: false
      sslCertificate: {
        id: '${subscription().id}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/applicationGateways/${name}/sslCertificates/frontendCert'
      }
    }
    type: 'Microsoft.Network/applicationGateways/httpListeners'
  }
]
var backendHttpSettings = [
  {
    name: 'gisPortalHttpsSetting'
    properties: {
      connectionDraining: {
        drainTimeoutInSec: 60
        enabled: true
      }
      cookieBasedAffinity: 'Disabled'
      path: '/arcgis/'
      pathRules: [
        {
          id: '${subscription().id}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/applicationGateways/${name}/urlPathMaps/gisEnterprisePathMap/pathRules/portalPathRule'
        }
      ]
      pickHostNameFromBackendAddress: true
      port: 7443
      probe: {
        id: '${subscription().id}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/applicationGateways/${name}/probes/gisPortalProbeName'
      }
      protocol: 'Https'
      requestTimeout: 600
      trustedRootCertificates: [
        {
          id: '${subscription().id}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/applicationGateways/${name}/trustedRootCertificates/trustedRoot'
        }
      ]
    }
    type: 'Microsoft.Network/applicationGateways/backendHttpSettingsCollection'
  }
  {
    name: 'gisServerHttpsSetting'
    properties: {
      connectionDraining: {
        drainTimeoutInSec: 60
        enabled: true
      }
      cookieBasedAffinity: 'Disabled'
      path: '/arcgis/'
      pathRules: [
        {
          id: '${subscription().id}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/applicationGateways/${name}/urlPathMaps/gisEnterprisePathMap/pathRules/serverPathRule'
        }
      ]
      pickHostNameFromBackendAddress: true
      port: 6443
      probe: {
        id: '${subscription().id}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/applicationGateways/${name}/probes/gisServerProbeName'
      }
      protocol: 'Https'
      requestTimeout: 600
      trustedRootCertificates: [
        {
          id: '${subscription().id}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/applicationGateways/${name}/trustedRootCertificates/trustedRoot'
        }
      ]
      urlPathMaps: [
        {
          id: '${subscription().id}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/applicationGateways/${name}/urlPathMaps/gisEnterprisePathMap'
        }
      ]
    }
    type: 'Microsoft.Network/applicationGateways/backendHttpSettingsCollection'
  }
]

module appGatewayPip '../../Modules/Microsoft.Network/publicIpAddresses/publicIpAddresses.bicep' = {
  name: 'AppGateway-PublicIP'
  params: {
    name: 'Esri-${name}-PIP'
    location: location
    publicIpAllocationMethod: 'Static'
    sku: 'Standard'
    publicIpAddressVersion: 'IPv4'
    tier: 'Regional'
    tags: tags
    zones: zoneArray 
  }
}

var frontEndIpConfigs = [
  {
    name: 'gisEnterpriseAppGatewayFrontendIP'
    properties: {
      httpListeners: [
        {
          id: '${subscription().id}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/applicationGateways/${name}/httpListeners/gisHttpEnterpriseDeploymentListner'
        }
        {
          id: '${subscription().id}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/applicationGateways/${name}/httpListeners/gisHttpsEnterpriseDeploymentListner'
        }
      ]
      privateIPAllocationMethod: 'Dynamic'
      publicIPAddress: {
        id: appGatewayPip.outputs.pipid
      }
    }
    type: 'Microsoft.Network/applicationGateways/frontendIPConfigurations'
  }
]
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
  dependsOn: [
    appGatewayPip
  ]
  properties: {
    trustedRootCertificates: [
      {
       name: 'trustedRoot'
       properties: {
        data: rootCert 
       }
      }
    ]
    autoscaleConfiguration: {
      maxCapacity: autoScaleMax
      minCapacity: autoScaleMin
    }
    backendAddressPools: backendPools
    backendHttpSettingsCollection: backendHttpSettings
    enableHttp2: enableHttp2
    frontendIPConfigurations: frontEndIpConfigs
    frontendPorts: frontEndPorts
    httpListeners: httpListeners
    probes: healthProbes
    sku: {
      name: skuName
      tier: skuName
    } 
    sslCertificates: [ {
        name: 'frontendCert'
        properties: {
          httpListeners: [
            {
              id: concat(subscription().id, '/resourceGroups/', resourceGroup().name, '/providers/Microsoft.Network/applicationGateways/', name, '/httpListeners/gisHttpsEnterpriseDeploymentListner')
            }
          ]
          data: publicCertString
        }
        type: 'Microsoft.Network/applicationGateways/sslCertificates'
      } ]
    urlPathMaps: urlPathMaps
    redirectConfigurations: redirectConfigurations
    requestRoutingRules: requestRoutingRules
    rewriteRuleSets: rewriteRuleSets
    gatewayIPConfigurations: [
      {
        name: 'ipConfig'
        properties: {
          subnet: {
            id: subnetId
          }
        }
      }
    ]
  }
  tags: tags
}

output publicIp string = appGatewayPip.outputs.ipAddress
