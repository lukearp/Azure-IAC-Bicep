param location string
param StroageAccountName string
param tags object

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-08-01' = {
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'  
  }
  location: location
  name: StroageAccountName
  properties:{
    supportsHttpsTrafficOnly: true
  } 
  tags: tags    
}
