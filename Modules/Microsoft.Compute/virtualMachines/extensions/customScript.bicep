param vmName string
param scriptName string
param arguments string
param fileUri string
param location string

resource vm 'Microsoft.Compute/virtualMachines@2023-07-01' existing = {
  name: vmName
}

resource extension 'Microsoft.Compute/virtualMachines/extensions@2023-07-01' = {
  parent: vm
  name: 'Script'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    typeHandlerVersion: '1.9'
    type: 'CustomScriptExtension'
    autoUpgradeMinorVersion: true
    settings: {}
    protectedSettings: {
      commandToExecute: 'powershell -ExecutionPolicy Unrestricted -File ${scriptName} ${arguments}'
      fileUris: [
        fileUri
      ]
      managedIdentity: {}
    }
  }
}
