targetScope = 'subscription'
var queryPackName = 'IaaS-Monitoring'
var resourceGroupName = 'azure-queries'
var location = 'eastus'
var tags = {
  Environment: 'Prod'
}

var queryStrings = [
  {
    name: guid('Server Down')
    displayName: 'Server Down'
    body: 'Heartbeat \r\n| summarize LastCall = max(TimeGenerated) by Computer \r\n| where LastCall < ago(5m)'
    categories: [
      'virtualmachines'
    ]
    labels: [
      'Availability'
    ] 
  }
  {
    name: guid('Memory Average over 95 Percent')
    displayName: 'Memory Average over 95 Percent'
    body: 'InsightsMetrics\r\n| where Namespace == "Memory" and TimeGenerated > ago(5m)\r\n| project Computer,  Percentage=100 - (Val / parse_json(Tags)["vm.azm.ms/memorySizeMB"] * 100)\r\n| summarize avg(Percentage) by Computer\r\n| where avg_Percentage > 95'
    categories: [
      'virtualmachines'
    ]
    labels: [
      'Performance'
    ] 
  }
  {
    name: guid('CPU over 95 Percent')
    displayName: 'CPU over 95 Percent'
    body: 'InsightsMetrics \r\n//| where Namespace == "Processor" and Name == "UtilizationPercentage" and TimeGenerated > ago(10m)\r\n| summarize avg(Val) by Computer\r\n| where avg_Val > 95'
    categories: [
      'virtualmachines'
    ]
    labels: [
      'Performance'
    ] 
  }
]

resource resourceGroupDeploy 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  location: location
  name: resourceGroupName
  tags: tags
}

module queryPack '../../../../../Modules/Microsoft.OperationalInsights/queryPacks.bicep' = {
  name: queryPackName
  scope: resourceGroup(resourceGroupDeploy.name)
  params: {
    location: location
    name: queryPackName
    tags: tags   
  }   
}

module queries '../../../../../Modules/Microsoft.OperationalInsights/queries/queries.bicep' = [for query in queryStrings: {
  name: '${query.name}-Query-Deployment'
  scope: resourceGroup(resourceGroupDeploy.name)
  params: {
    name: query.name
    displayName: query.displayName
    body: query.body
    queryPackName: queryPack.name
    categories: query.categories
    labels: query.labels     
  }  
}]
