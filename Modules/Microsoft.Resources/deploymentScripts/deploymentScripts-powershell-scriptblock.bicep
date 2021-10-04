param name string
param location string = resourceGroup().location
param managedIdentityId string
param psScriptContent string
param arguments string
@allowed([
  'Always'
  'OnSuccess'
  'OnExpiration'
])
param cleanupPreference string = 'Always'
param azPowershellVersion string = '5.9'
param supportingScriptUris array = []
param tags object = {}

resource deploymentScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  kind: 'AzurePowerShell' 
  location: location
  name: name
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityId}':{}
    }  
  }
  properties: {
    arguments: arguments
    scriptContent: psScriptContent 
    azPowerShellVersion: azPowershellVersion
    retentionInterval: 'PT1H' 
    cleanupPreference: cleanupPreference 
    supportingScriptUris: supportingScriptUris     
  }
  tags: tags 
}

output results object = deploymentScript.properties.outputs
