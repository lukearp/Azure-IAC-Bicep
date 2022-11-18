param name string
param location string
param hostpoolResourceId string
@allowed([
  'RemoteApp'
  'Desktop'
])
param applicationGroupType string
param description string

resource applicationGroup 'Microsoft.DesktopVirtualization/applicationGroups@2022-04-01-preview' = {
  name: name
  location: location
  properties: {
    applicationGroupType: applicationGroupType
    hostPoolArmPath: hostpoolResourceId
    description: description
    friendlyName: name    
  }   
}

output id string = applicationGroup.id
