param name string
param location string
param friendlyName string
param description string
param applicationGroupReferences array = []

resource workspace 'Microsoft.DesktopVirtualization/workspaces@2022-02-10-preview' = {
  name: name
  location: location
  properties: {
    friendlyName: friendlyName
    description: description
    applicationGroupReferences: applicationGroupReferences   
  }   
}
