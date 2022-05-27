targetScope = 'subscription'
var name = 'luke-projects-monitor'
var location = 'eastus'
var resourceGroupName = 'azure-monitor'
var tags = {
  Environment: 'Prod'
}
resource resourceGroupDeploy 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location 
  tags: tags
}

module workspaces '../../../../../Modules/Microsoft.OperationalInsights/workspaces.bicep' = {
  name: '${name}-Monitor-Workspace'
  scope: resourceGroup(resourceGroupDeploy.name)
  params: {
     name: name
     location: location 
     retentionInDays: 90
     tags: tags   
  }   
}

output workspaceResourceId string = workspaces.outputs.workspaceResourceId
