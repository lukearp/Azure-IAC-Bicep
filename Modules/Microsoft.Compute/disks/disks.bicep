param name string
param location string
param zones array = []
@allowed([
  'Standard_LRS'
  'Premium_LRS'
  'StandardSSD_LRS'
  'UltraSSD_LRS'
  'Premium_ZRS'
  'StandardSSD_ZRS'
])
param sku string 
param diskSizeGB int
@allowed([
  'Attach'
  'Copy'
  'CopyStart'
  'Empty'
  'FromImage'
  'Import'
  'ImportSecure'
  'Restore'
  'Upload'
  'UploadPreparedSecure'
])
param createOption string = 'Empty'
param tags object = {}

resource disk 'Microsoft.Compute/disks@2021-04-01' = {
  location: location
  name: name
  zones: zones
  sku: {
    name: sku
  }
  properties: {
    diskSizeGB: diskSizeGB 
    creationData: {
      createOption: createOption 
    }
  } 
  tags: tags      
}
