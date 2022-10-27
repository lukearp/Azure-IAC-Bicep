param name string
param nsgId string
param storagAccountId string
param location string
@allowed([
  1
  2
])
param version int = 2
param retentionInDays int = 7

resource networkWatcher 'Microsoft.Network/networkWatchers@2022-05-01' existing = {
  name: 'NetworkWatcher_${location}'
}

resource flowLog 'Microsoft.Network/networkWatchers/flowLogs@2022-05-01' = {
  parent: networkWatcher
  name: name
  location: location
  properties: {
    storageId: storagAccountId
    targetResourceId: nsgId
    enabled: true
    format: {
      type: 'JSON'
      version: version  
    } 
    retentionPolicy: {
      enabled: true
      days: retentionInDays  
    }    
  }   
}
