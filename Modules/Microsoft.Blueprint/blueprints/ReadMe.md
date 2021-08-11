# Parameters
param | type | notes
------|------|------
name | string | Blueprint Name
displayName | string | Display Name for blueprint
description | string | Description of Blueprint
parameters | object | Blueprint parameters
resourceGroups | object | Blueprint ResourceGroups
versions | array | Array of Version objects.  Version properties are name and changeNotes
templateArtifacts | array | Array of Template Artifcate objects


# Sample Module
```
targetScope = 'managementGroup'

var templateArtificats = [
  {
    kind: 'template'
    name: 'Template'  
    properties: {
      description: 'Test-Artifact'
      displayName: 'Template'
      template: {
        '$schema': 'http://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#'
        contentVersion: '1.0.0.0'
        parameters: {
          agency: {
            type: 'string'          
          }        
        }
        resources: [
          {
            name: 'Test-Template-Spec'
            type: 'Microsoft.Resources/resourceGroups'
            apiVersion: '2019-10-01'
            location: 'eastus'
            dependsOn: []
            tags: {
              agency: '[parameters(\'agency\')]'
            }
          }
        ]
      }
      parameters: {
        agency: {
           value: '[[parameters(\'agency\')]'
        }
      }
    } 
  }
]

var versions = [
  {
    name: 'v1'
    changeNotes: 'My changes'
  }
]

module def '../Modules/Microsoft.Blueprint/blueprints/blueprints-mg.bicep' = {
  name: 'Blueprint-Def' 
  params: {
    description: 'My-Test-Blueprint' 
    displayName: 'My-Blueprint'
    name: 'My-Test-Blueprint'
    parameters: {
      agency: {
        type: 'string'
      }
    } 
    templateArtifacts: templateArtificats
    versions: versions 
  }   
}
```