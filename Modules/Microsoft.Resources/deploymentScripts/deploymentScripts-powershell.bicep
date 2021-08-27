param name string
param location string = resourceGroup().location
param managedIdentityId string
param pscriptUri string
param arguments string
@allowed([
  'Always'
  'OnSuccess'
  'OnExpiration'
])
param cleanupPreference string = 'Always'
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
    primaryScriptUri: pscriptUri 
    azPowerShellVersion: '5.9'
    retentionInterval: 'PT1H' 
    cleanupPreference: cleanupPreference     
  }
  tags: tags 
}

output results object = deploymentScript.properties.outputs
