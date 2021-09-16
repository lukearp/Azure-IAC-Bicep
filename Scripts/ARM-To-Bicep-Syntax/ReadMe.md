# What does this module do?
Takes a JSON ARM Template File and parses it to be consumed as a Bicep Module.

I created it to use in CI/CD Pipelines.  I was automating Blueprint and Template Spec definitions, and wanted a way to import other "Built" bicep files as the Template Paramter.  The script outputs a gen.bicep file in the folder where it is ran.  

# What does this module Require?
Any ARM Json file should be able to be used as the source.

# Parameters
param | type | notes
------|------|------
path | string | Source path to JSON ARM Template file
scope | string | Allowed Values are subscription or managementGroup.  This should match the scope of your main deployment

# Sample Module
Generate gen.bicep:
```dotnetcli
.\ARM-to-Bicep-Syntax.ps1 -path .\arm-template.json -scope managementGroup
```
Reference gen.bicep as a Module for Blueprint Artifact:
```dotnetcli
module template 'gen.bicep' = {
  name: 'Bicep-Artifact'
  params: {}
}

resource artifacts 'Microsoft.Blueprint/blueprints/artifacts@2018-11-01-preview' = {
  kind: 'template'
  parent: blueprintDef
  name: 'PolicyInitiative'
  properties: {
    parameters:{
      policyName: {
        value: '[parameters(\'deploy_policyName\')]'
      }
    }
    template: template.outputs.templateObj 
  }  
}
```