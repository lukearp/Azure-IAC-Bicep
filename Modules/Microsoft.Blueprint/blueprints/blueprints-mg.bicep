targetScope = 'managementGroup'
param name string
param displayName string
param description string
param parameters object = {}
param resourceGroups object = {}
param versions array = []
/*
Full Artificat objects
Policy:
  kind: 'policyAssignment'
  properties: {
    dependsOn: [ 'string' ]
    description: 'string'
    displayName: 'string'
    parameters: {}
    policyDefinitionId: 'string'
    resourceGroup: 'string'
  }
Role Assignment:
  kind: 'roleAssignment'
  properties: {
    dependsOn: [ 'string' ]
    description: 'string'
    displayName: 'string'
    principalIds: any()
    resourceGroup: 'string'
    roleDefinitionId: 'string'
  }
Template:
  kind: 'template'
  properties: {
    dependsOn: [ 'string' ]
    description: 'string'
    displayName: 'string'
    parameters: {}
    resourceGroup: 'string'
    template: any()
  }
*/
param templateArtifacts array

resource blueprintDef 'Microsoft.Blueprint/blueprints@2018-11-01-preview' = {
  name: name 
  properties: {
    displayName: displayName
    description: description
    targetScope: 'subscription' 
    parameters: parameters
    resourceGroups: resourceGroups 
  }
}

resource artifacts 'Microsoft.Blueprint/blueprints/artifacts@2018-11-01-preview' = [for artifcat in templateArtifacts : {
  kind: 'template'
  parent: blueprintDef
  name: artifcat.name
  properties: artifcat.properties      
}]

resource blueprintVersions 'Microsoft.Blueprint/blueprints/versions@2018-11-01-preview' = [for version in versions : {
  parent: blueprintDef
  name: version.name
  properties: {
    blueprintName: name
    changeNotes: version.changeNotes
    description: description
    displayName: displayName 
    parameters: parameters
    resourceGroups: resourceGroups
    targetScope: 'subscription'    
  }   
}] 
