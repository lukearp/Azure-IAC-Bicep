targetScope = 'subscription'
param location string
param name string
param resourceGroupName string
param privateLinkSubnetId string
param disablePublicAccess bool = false
param initialAdmin string
param sqlAdminUser string
@secure()
param sqlAdminPassword string
param addDNSRecords bool = false
param dnsSubscriptionId string = subscription().subscriptionId
param dnsRgName string = resourceGroupName
param azureGovernment bool = false
param autoApprovePLToStorage bool = false
param managedIdentityId string = ''
param tags object = {}

resource rg 'Microsoft.Resources/resourceGroups@2019-05-01' = {
  name: resourceGroupName
  location: location
}

var storageSuffix = azureGovernment == false ? 'core.windows.net' : 'core.usgovcloudapi.net'
var storageName = 'dl${substring(replace(guid('${name}-${location}-${resourceGroupName}-${subscription().id}'),'-',''),0,15)}'
module storageAccount '../../Modules/Microsoft.Storage/storageAccounts/storageAccounts.bicep' = {
  name: 'StorageAccount-Deploy'
  scope: resourceGroup(rg.name)
  params: {
    kind: 'StorageV2'
    location: location
    name: storageName
    disablePubliAccess: true
    enableHierarchicalNamespace: true
    sku: 'Standard_LRS'
    supportsHttpsTrafficOnly: true
    publicNetworkAccess: true  
    tags: tags        
  }  
}

module synapse '../../Modules/Microsoft.Synapse/workspace.bicep' = {
  name: 'Synapse-Deploy'
  scope: resourceGroup(rg.name)
  params: {
    location: location
    name: name
    tags: tags
    storageDfsEndpoint: storageAccount.outputs.endpoints.dfs
    strorageResourceId: storageAccount.outputs.storageAccountId  
    createPrivateEndpointForStorage: true
    initialAdmin: initialAdmin
    sqlAdminPassword: sqlAdminPassword
    sqlAdminUser: sqlAdminUser
    disablePublicAccess: disablePublicAccess 
  }  
}

module autoApprove '../../Modules/Microsoft.Resources/deploymentScripts/deploymentScripts-powershell.bicep' = if(autoApprovePLToStorage) {
  name: 'Approve-PL'
  scope: resourceGroup(rg.name)
  dependsOn: [
    synapse
  ] 
  params: {
     arguments: '-resourceId ${storageAccount.outputs.storageAccountId}'
     managedIdentityId: managedIdentityId
     name: 'Approve-Storage'
     pscriptUri: 'https://raw.githubusercontent.com/lukearp/Azure-IAC-Bicep/master/Standard-Deployments/Private-Synapse/Script/Approve-Private.ps1'
     location: 'eastus'
     cleanupPreference: 'OnSuccess'     
  }   
} 

module privateLinkBlob '../../Modules/Microsoft.Network/privateEndpoints/privateEndpoints.bicep' = {
  name: 'DL-PL-Blob-Deploy'
  scope: resourceGroup(rg.name)
  params: {
    location: location
    name: '${split(storageAccount.outputs.storageAccountId,'/')[8]}-blob-pl'
    remoteServiceResourceId: storageAccount.outputs.storageAccountId
    subnetResourceId: privateLinkSubnetId
    targetSubResource: [
      'blob'
    ]
    tags: tags    
  }   
}

module privateLinkDfs '../../Modules/Microsoft.Network/privateEndpoints/privateEndpoints.bicep' = {
  name: 'DL-PL-DFS-Deploy'
  scope: resourceGroup(rg.name)
  params: {
    location: location
    name: '${split(storageAccount.outputs.storageAccountId,'/')[8]}-dfs-pl'
    remoteServiceResourceId: storageAccount.outputs.storageAccountId
    subnetResourceId: privateLinkSubnetId
    targetSubResource: [
      'dfs'
    ]  
    tags: tags      
  }   
}

module privateLinkSqlSynapse '../../Modules/Microsoft.Network/privateEndpoints/privateEndpoints.bicep' = {
  name: 'Synapse-PL-SQL-Deploy'
  scope: resourceGroup(rg.name)
  params: {
    location: location
    name: '${name}-Sql-pl'
    remoteServiceResourceId: synapse.outputs.synapsId
    subnetResourceId: privateLinkSubnetId
    targetSubResource: [
      'Sql'
    ] 
    tags: tags  
  } 
}

module privateLinkDevSynapse '../../Modules/Microsoft.Network/privateEndpoints/privateEndpoints.bicep' = {
  name: 'Synapse-PL-Dev-Deploy'
  scope: resourceGroup(rg.name)
  params: {
    location: location
    name: '${name}-Dev-pl'
    remoteServiceResourceId: synapse.outputs.synapsId
    subnetResourceId: privateLinkSubnetId
    targetSubResource: [
      'Dev'
    ] 
    tags: tags  
  } 
}

module dnsZonesSql 'dnsrecordLoop.bicep' = if(addDNSRecords) {
  name: 'Record-Synapse-SQL-Creation'
  scope: resourceGroup(dnsSubscriptionId,dnsRgName)
  params: {
    azureGovernment: azureGovernment
    records: privateLinkSqlSynapse.outputs.customerDnsConfigs  
  }  
}

module dnsZonesDev 'dnsrecordLoop.bicep' = if(addDNSRecords) {
  name: 'Record-Synapse-Dev-Creation'
  scope: resourceGroup(dnsSubscriptionId,dnsRgName)
  params: {
    azureGovernment: azureGovernment
    records: privateLinkDevSynapse.outputs.customerDnsConfigs  
  }  
}

module blobDNSZone '../../Modules/Microsoft.Network/privateDnsZones/privateDnsZones.bicep' = if(addDNSRecords) {
  name: '${name}-BlobDNSZone' 
  scope: resourceGroup(dnsSubscriptionId,dnsRgName)
  params: {
    zoneName: 'privatelink.blob.${storageSuffix}' 
    createARecord: true
    aRecordName: split(storageAccount.outputs.storageAccountId,'/')[8]  
    aRecordIp: privateLinkBlob.outputs.customerDnsConfigs[0].ipAddresses[0] 
    vnetAssociations: [
    ]
    tags: tags 
  }
}

module dfsDNSZone '../../Modules/Microsoft.Network/privateDnsZones/privateDnsZones.bicep' = if(addDNSRecords) {
  name: '${name}-DfsDNSZone' 
  scope: resourceGroup(dnsSubscriptionId,dnsRgName)
  params: {
    zoneName: 'privatelink.dfs.${storageSuffix}' 
    createARecord: true
    aRecordName: split(storageAccount.outputs.storageAccountId,'/')[8]  
    aRecordIp: privateLinkDfs.outputs.customerDnsConfigs[0].ipAddresses[0]
    vnetAssociations: [
    ]
    tags: tags 
  }
}
