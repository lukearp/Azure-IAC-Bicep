param location string
param namePrefix string
param aiStudioResourceId string

resource sampleModel 'Microsoft.MachineLearningServices/workspaces@2024-04-01' = {
  name: '${namePrefix}-SampleProject'
  location: location
  sku: {
    name: 'Basic'
    tier: 'Basic'
  }  
  kind: 'Project'
  identity: { 
    type: 'SystemAssigned'
  }
  properties: {
     hubResourceId: aiStudioResourceId
     publicNetworkAccess: 'Enabled'
     enableDataIsolation: true
     hbiWorkspace: false
     friendlyName: '${namePrefix}-SampleProject' 
  } 
}
