param vmName string
param commandName string
param location string = resourceGroup().location
param scriptUri string = ''
param scriptString string = ''
@metadata({
  description: 'Array of Objects\n {\n\tname:\'Name\'\n\tvalue:\'Value\'\n}'
})
param scriptParameters array = []
@metadata({
  description: 'Array of Objects\n {\n\tname:\'Name\'\n\tvalue:\'Value\'\n}'
})
param scriptProtectedParameters array = []
param runAsUser string = ''
@secure()
param runAsPassword string = ''
param runAsync bool = false

resource vm 'Microsoft.Compute/virtualMachines@2021-03-01' existing = {
  name: vmName
}

var sourceObject = scriptUri != '' ? {
  commandId: 'RunPowerShellScript'
  scriptUri: scriptUri
}:{
  commandId: 'RunPowerShellScript'
  script: scriptString
}

var commanProperties = runAsUser != '' && runAsPassword != '' ? {
  source: sourceObject
  parameters: scriptParameters
  protectedParameters: scriptProtectedParameters
  asyncExecution: runAsync
}:{
  source: sourceObject
  parameters: scriptParameters
  protectedParameters: scriptProtectedParameters
  asyncExecution: runAsync
  runAsUser: runAsUser
  runAsPassword: runAsPassword
}  

resource command 'Microsoft.Compute/virtualMachines/runCommands@2021-03-01' = {
  name: commandName   
  location: location 
  parent: vm
  properties: commanProperties
}
