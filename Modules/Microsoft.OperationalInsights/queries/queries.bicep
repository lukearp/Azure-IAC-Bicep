param name string
param displayName string
param queryPackName string
param body string
@allowed([
  'security'
  'network'
  'management'
  'virtualmachines'
  'container'
  'audit'
  'desktopanalytics'
  'workloads'
  'resources'
  'applications'
  'monitor'
  'databases'
  'windowsvirtualdesktop'
])
param categories array = []
param resourceTypes array = [
  'microsoft.operationalinsights/workspaces'
]
param labels array = []

resource queryPack 'Microsoft.OperationalInsights/queryPacks@2019-09-01' existing = {
  name: queryPackName
}

resource query 'Microsoft.OperationalInsights/queryPacks/queries@2019-09-01' = {
   name: name
   parent: queryPack
   properties: {
      displayName: displayName
      body: body
      related: {
        categories: categories
        resourceTypes: resourceTypes
      } 
      tags: {
        labels: labels 
      }      
   } 
}
