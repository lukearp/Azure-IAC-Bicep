param name string
param location string
param azureGov bool = false
param logicAppVNETSubnetId string = ''
param enableVNETIntegration bool = false
param enablePrivateLink bool = false
param publicNetworkAccessEnabled bool = true
param privateLinkSubnetId string = ''
param dnsZoneRg string = ''
param dnsZoneSubscriptionId string = ''
param associateDnsZonesWithVNET bool = false
param dnsVnetId string = ''
param tags object = {}

var nameSuffix = substring(replace(guid('${resourceGroup().name}-${location}-${subscription().id}'),'-',''),0,15)
var storageSuffix = azureGov == true ? 'core.usgovcloudapi.net' : 'core.windows.net'
var webSuffix = azureGov == true ? 'azurewebsites.us' : 'azurewebsites.net'
module appPlan '../../Modules/Microsoft.Web/serverFarms/serverFarms-StandardLogicApps.bicep' = {
  name: '${name}-Plan-Deploy' 
  params: {
     name: '${name}-Plan'
     location: location
     skuName: 'WS1'
     skuTier: 'WorkflowStandard'
     tags: tags    
  } 
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: 'la${nameSuffix}' 
  kind: 'StorageV2'
  location: location
  tags: tags
  sku: {
    name: 'Standard_LRS' 
  }
  properties: {
     publicNetworkAccess: enablePrivateLink == true ? publicNetworkAccessEnabled == true ? 'Enabled' : 'Disabled' : 'Enabled'
  }    
} 

module getSubnetProperties 'subnetProperties.bicep' = if(enableVNETIntegration){
  name: 'Get-Subnet-Properties'
  scope: resourceGroup(split(logicAppVNETSubnetId,'/')[4])
  params: {
    subnetId: logicAppVNETSubnetId 
  }   
}

module subnetSetup 'subnetSetup.bicep' = if(enableVNETIntegration){
  name: '${split(logicAppVNETSubnetId,'/')[10]}-Subnet-Setup'
  scope: resourceGroup(split(logicAppVNETSubnetId,'/')[4])
  params: {
    subnetId: logicAppVNETSubnetId
    properties: getSubnetProperties.outputs.properties 
  }   
}

module logicApp '../../Modules/Microsoft.Web/sites/sites-logicapp.bicep' = {
  name: '${name}-LogicApp-Deploy'
  params: {
    appServicePlanId: appPlan.outputs.planId
    location: location
    name: name
    storageAccountConnectionString: 'DefaultEndpointsProtocol=https;AccountName=la${nameSuffix};AccountKey=${storageAccount.listKeys().keys[0].value};EndpointSuffix=${storageSuffix}' 
    logicAppVNETSubnetId: enableVNETIntegration == false ? '' : logicAppVNETSubnetId
    publicNetworkAccessEnabled: enablePrivateLink == true ? publicNetworkAccessEnabled == true ? 'Enabled' : 'Disabled' : 'Enabled'
    tags: tags    
  }
  dependsOn: [
    subnetSetup
  ]
}

module logicAppPrivateLink '../../Modules/Microsoft.Network/privateEndpoints/privateEndpoints.bicep' = if(enablePrivateLink == true){
   name: '${name}-LogicApp-PL-Deploy'
   params: {
    location: location
    name: '${name}-LogicApp-PL'
    remoteServiceResourceId: logicApp.outputs.resourceId
    subnetResourceId: privateLinkSubnetId
    tags: tags
    targetSubResource: [
      'sites'
    ]       
   }
}

module storageBlobPrivateLink '../../Modules/Microsoft.Network/privateEndpoints/privateEndpoints.bicep' = if(enablePrivateLink == true){
  name: '${storageAccount.name}-Blob-PL-Deploy'
  params: {
    location: location
    name: '${storageAccount.name}-Blob-PL'
    remoteServiceResourceId: storageAccount.id
    subnetResourceId: privateLinkSubnetId
    targetSubResource: [
      'blob'
    ]     
  }  
}

module storageFilePrivateLink '../../Modules/Microsoft.Network/privateEndpoints/privateEndpoints.bicep' = if(enablePrivateLink == true){
  name: '${storageAccount.name}-File-PL-Deploy'
  params: {
    location: location
    name: '${storageAccount.name}-File-PL'
    remoteServiceResourceId: storageAccount.id
    subnetResourceId: privateLinkSubnetId
    targetSubResource: [
      'file'
    ]     
  }  
}

module logicAppPrivateLinkDns '../../Modules/Microsoft.Network/privateDnsZones/privateDnsZones.bicep' = if(enablePrivateLink == true){
  name: '${name}-LogicApp-DNS-Deploy'
  scope: resourceGroup(dnsZoneSubscriptionId, dnsZoneRg)
  params: {
    zoneName: 'privatelink.${webSuffix}' 
    createARecord: true
    aRecordName: name
    aRecordIp: logicAppPrivateLink.outputs.customerDnsConfigs[0].ipAddresses[0]
    vnetAssociations: associateDnsZonesWithVNET == true ? [
      {
        id: dnsVnetId
        registrationEnabled: false
      }
    ] : []
  }  
}

module blobAppPrivateLinkDns '../../Modules/Microsoft.Network/privateDnsZones/privateDnsZones.bicep' = if(enablePrivateLink == true){
  name: '${name}-Blob-DNS-Deploy'
  scope: resourceGroup(dnsZoneSubscriptionId, dnsZoneRg)
  params: {
    zoneName: 'privatelink.blob.${storageSuffix}' 
    createARecord: true
    aRecordName: storageAccount.name 
    aRecordIp: storageBlobPrivateLink.outputs.customerDnsConfigs[0].ipAddresses[0]
    vnetAssociations: associateDnsZonesWithVNET == true ? [
      {
        id: dnsVnetId
        registrationEnabled: false
      }
    ] : []
  }  
}

module fileAppPrivateLinkDns '../../Modules/Microsoft.Network/privateDnsZones/privateDnsZones.bicep' = if(enablePrivateLink == true){
  name: '${name}-File-DNS-Deploy'
  scope: resourceGroup(dnsZoneSubscriptionId, dnsZoneRg)
  params: {
    zoneName: 'privatelink.file.${storageSuffix}'
    createARecord: true
    aRecordName: storageAccount.name
    aRecordIp: storageFilePrivateLink.outputs.customerDnsConfigs[0].ipAddresses[0]
    vnetAssociations: associateDnsZonesWithVNET == true ? [
      {
        id: dnsVnetId
        registrationEnabled: false
      }
    ] : []
  }  
}
