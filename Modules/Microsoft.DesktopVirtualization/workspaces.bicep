param name string
param location string
param description string
param applicationGroupReferences array = [
  
]
resource workspace 'Microsoft.DesktopVirtualization/workspaces@2022-04-01-preview' = {
  name: name
  location: location
  properties: {
    friendlyName: name
    description: description 
    applicationGroupReferences: applicationGroupReferences  
  }  
}
