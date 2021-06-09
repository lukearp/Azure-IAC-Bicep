module templateSpec '../../../../Modules/Microsoft.Resources/templateSpecs/templateSpecs.bicep' = {
  name: 'My-Template-Spec'
  scope: resourceGroup('template-spec')
  params: {
    name: 'Resource-Group-Deploy'
    template: {
      '$schema': 'http://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#'
      contentVersion: '1.0.0.0'
      parameters: {
        agency: {
          type: 'string'
        }
        environment: {
          type: 'string'
        }
        application: {
          type: 'string'
        }
        Name: {
          type: 'string'
        }
        createdby: {
          type: 'string'
        }
        businessowner: {
          type: 'string'
        }
        itowner: {
          type: 'string'
        }
        backup: {
          type: 'string'
          allowedValues: [
            'True'
            'False'
          ]
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
            environment: '[parameters(\'environment\')]'
            application: '[parameters(\'application\')]'
            Name: '[parameters(\'Name\')]'
            createdby: '[parameters(\'createdby\')]'
            businessowner: '[parameters(\'businessowner\')]'
            itowner: '[parameters(\'itowner\')]'
            backup: '[parameters(\'backup\')]'
          }
        }
      ]
    }
    version: 'v1'
  }
}
