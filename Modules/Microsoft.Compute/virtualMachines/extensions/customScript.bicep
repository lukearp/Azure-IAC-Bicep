param vmName string
param name string = 'CustomScriptExtension'
param scriptName string
param arguments string
param fileUri string
param location string
@allowed([
  'Windows'
  'Linux'
])
param osType string
param storageAccountName string = ''
@secure()
param storageAccountKey string = ''

var extensionType = osType == 'Windows' ? 'CustomScriptExtension' : 'CustomScript'
var publisher = osType == 'Windows' ? 'Microsoft.Compute' : 'Microsoft.Azure.Extensions'
var typeHandlerVersion = osType == 'Windows' ? '1.9' : '2.0'

resource vm 'Microsoft.Compute/virtualMachines@2023-07-01' existing = {
  name: vmName
}

var commandStart = osType == 'Windows' ? 'powershell -ExecutionPolicy Unrestricted -File ' : 'bash -c ./'

var protectedSettings = storageAccountName == '' ? {
  commandToExecute: '${commandStart}${scriptName} ${arguments}'
  fileUris: [
    fileUri
  ]
  managedIdentity: {}
} : {
  commandToExecute: '${commandStart}${scriptName} ${arguments}'
  fileUris: [
    fileUri
  ]
  storageAccountName: storageAccountName
  storageAccountKey: storageAccountKey
}

resource extension 'Microsoft.Compute/virtualMachines/extensions@2023-07-01' = {
  parent: vm
  name: name
  location: location
  properties: {
    publisher: publisher
    typeHandlerVersion: typeHandlerVersion
    type: extensionType
    autoUpgradeMinorVersion: true
    settings: {}
    protectedSettings: protectedSettings
  }
}

// Used for testing
//output protectedSettings object = protectedSettings
