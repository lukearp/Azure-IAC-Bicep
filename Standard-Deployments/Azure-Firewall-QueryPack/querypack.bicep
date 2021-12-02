param queryPackName string = 'AzFirewall-FrontDoorWaf'
param location string

resource querypack_resource 'Microsoft.OperationalInsights/querypacks@2019-09-01-preview' = {
  name: queryPackName
  location: location
  properties: {}
}

resource querypacks_FrontdoorAccessLog 'Microsoft.OperationalInsights/querypacks/queries@2019-09-01-preview' = {
  parent: querypack_resource
  name: '1f83b5fa-a843-408a-a4fa-095a35c926da'
  properties: {
    displayName: 'FrontdoorAccessLog'
    body: 'AzureDiagnostics\r\n| where Category == "FrontdoorAccessLog"\r\n| project Method=httpMethod_s, RequestUri=requestUri_s, ClientIp=clientIp_s, Response=httpStatusCode_s,RoutingRule=routingRuleName_s,Backend=backendHostname_s, TimeGenerated\r\n| sort by TimeGenerated desc '
    related: {
      categories: []
      resourceTypes: [
        'microsoft.operationalinsights/workspaces'
      ]
    }
    tags: {
      labels: []
    }
  }
}

resource querypacks_FrontdoorWebApplicationFirewallLog 'Microsoft.OperationalInsights/querypacks/queries@2019-09-01-preview' = {
  parent: querypack_resource
  name: '55f6e3eb-6f7d-4b6c-bc56-854791e1fdc4'
  properties: {
    displayName: 'FrontdoorWebApplicationFirewallLog'
    body: 'AzureDiagnostics\r\n| where Category == "FrontdoorWebApplicationFirewallLog"\r\n| project TimeGenerated, RequestUri=requestUri_s,ClientIP=clientIp_s,Rule=ruleName_s,Policy=PolicyName_s,Action=action_s,PolicyMode=policyMode_s\r\n| sort by TimeGenerated desc '
    related: {
      categories: []
      resourceTypes: [
        'microsoft.operationalinsights/workspaces'
      ]
    }
    tags: {
      labels: []
    }
  }
}

resource querypacks_AzureFirewallNetworkRule 'Microsoft.OperationalInsights/querypacks/queries@2019-09-01-preview' = {
  parent: querypack_resource
  name: '8c97a946-2afc-4bf3-a88c-6ecf12a2ade2'
  properties: {
    displayName: 'AzureFirewallNetworkRule'
    body: 'AzureDiagnostics\r\n| where Category == "AzureFirewallNetworkRule" and msg_s !contains "DNAT"\r\n| project msg_s,TimeGenerated\r\n| extend Protocol=split(msg_s,\' \')[0], Source=split(split(msg_s,\'from \')[1],\':\')[0], Destination=split(split(msg_s,\'to \')[1],\':\')[0], Port=split(split(split(msg_s,\'to \')[1],\':\')[1],\'.\')[0], Action=split(split(msg_s,\'Action: \')[1],\'.\')[0]\r\n| project Source,Destination,Port,Action,TimeGenerated\r\n| sort by TimeGenerated desc '
    related: {
      categories: []
      resourceTypes: [
        'microsoft.network/azurefirewalls'
      ]
    }
    tags: {
      labels: []
    }
  }
}

resource querypacks_AzureFirewallNetworkRuleDNAT 'Microsoft.OperationalInsights/querypacks/queries@2019-09-01-preview' = {
  parent: querypack_resource
  name: 'b1738571-13f5-4c4a-887d-188c43c3d6bf'
  properties: {
    displayName: 'AzureFirewallNetworkRule-DNAT'
    body: 'AzureDiagnostics\r\n| where Category == "AzureFirewallNetworkRule" and msg_s contains "DNAT"\r\n| project msg_s,TimeGenerated\r\n| extend Protocol=split(msg_s,\' \')[0], Source=split(split(msg_s,\'from \')[1],\':\')[0], Destination=split(split(msg_s,\'to \')[1],\':\')[0], Port=split(split(split(msg_s,\'to \')[1],\':\')[1],\' \')[0], Target=split(split(msg_s,\'DNAT\\\'ed to \')[1],\':\')[0],TargetPort=split(split(msg_s,\'DNAT\\\'ed to \')[1],\':\')[1]\r\n| project Source,Destination,Port,Target,TargetPort,TimeGenerated\r\n| sort by TimeGenerated desc '
    related: {
      categories: []
      resourceTypes: [
        'microsoft.network/azurefirewalls'
      ]
    }
    tags: {
      labels: []
    }
  }
}

resource querypacks_AzureFirewallApplicationRule 'Microsoft.OperationalInsights/querypacks/queries@2019-09-01-preview' = {
  parent: querypack_resource
  name: 'c86968cb-ec68-4bfa-94bb-7aa22e39d0bb'
  properties: {
    displayName: 'AzureFirewallApplicationRule'
    body: 'AzureDiagnostics\r\n| where Category == "AzureFirewallApplicationRule"\r\n| project TimeGenerated, msg_s\r\n| extend Source=split(split(msg_s,\'request from \')[1],\' to\')[0], Protcol=split(msg_s,\' \')[0], Destination=split(split(msg_s,\' to \')[1],\'. \')[0], Action=split(split(msg_s,\'Action: \')[1],\'. \')[0], URL=split(split(msg_s,\'Url: \')[1],\'. \')[0], Rule=split(split(msg_s,\'Rule: \')[1],\'. \')[0], WebCategory=split(split(msg_s,\'Web Category: \')[1],\'. \')[0]\r\n| project TimeGenerated,Protcol, Source, Destination, Action, URL, Rule, WebCategory\r\n| sort by TimeGenerated desc '
    related: {
      categories: []
      resourceTypes: [
        'microsoft.network/azurefirewalls'
      ]
    }
    tags: {
      labels: []
    }
  }
}
