param name string
param location string
param logicAppResourceId string
param storageAccountResourceId string
param associateDnsZonesWithVNET bool
param dnsVnetId string
param privateLinkSubnetId string
param azureGov bool
param dnsZoneRg string
param dnsZoneSubscriptionId string
param tags object = {}

var stroageAccountName = split(storageAccountResourceId,'/')[8]
var storageSuffix = azureGov == true ? 'core.usgovcloudapi.net' : 'core.windows.net'
var webSuffix = azureGov == true ? 'azurewebsites.us' : 'azurewebsites.net'

module logicAppPrivateLink '../../Modules/Microsoft.Network/privateEndpoints/privateEndpoints.bicep' = {
  name: '${name}-LogicApp-PL-Deploy'
  params: {
   location: location
   name: '${name}-LogicApp-PL'
   remoteServiceResourceId: logicAppResourceId
   subnetResourceId: privateLinkSubnetId
   tags: tags
   targetSubResource: [
     'sites'
   ]       
  }
}

module storageBlobPrivateLink '../../Modules/Microsoft.Network/privateEndpoints/privateEndpoints.bicep' = {
 name: '${stroageAccountName}-Blob-PL-Deploy'
 params: {
   location: location
   name: '${stroageAccountName}-Blob-PL'
   remoteServiceResourceId: storageAccountResourceId
   subnetResourceId: privateLinkSubnetId
   targetSubResource: [
     'blob'
   ]     
 }  
}

module storageFilePrivateLink '../../Modules/Microsoft.Network/privateEndpoints/privateEndpoints.bicep' = {
 name: '${stroageAccountName}-File-PL-Deploy'
 params: {
   location: location
   name: '${stroageAccountName}-File-PL'
   remoteServiceResourceId: storageAccountResourceId
   subnetResourceId: privateLinkSubnetId
   targetSubResource: [
     'file'
   ]     
 }  
}

module logicAppPrivateLinkDns '../../Modules/Microsoft.Network/privateDnsZones/privateDnsZones.bicep' = {
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

module blobAppPrivateLinkDns '../../Modules/Microsoft.Network/privateDnsZones/privateDnsZones.bicep' = {
 name: '${name}-Blob-DNS-Deploy'
 scope: resourceGroup(dnsZoneSubscriptionId, dnsZoneRg)
 params: {
   zoneName: 'privatelink.blob.${storageSuffix}' 
   createARecord: true
   aRecordName: stroageAccountName
   aRecordIp: storageBlobPrivateLink.outputs.customerDnsConfigs[0].ipAddresses[0]
   vnetAssociations: associateDnsZonesWithVNET == true ? [
     {
       id: dnsVnetId
       registrationEnabled: false
     }
   ] : []
 }  
}

module fileAppPrivateLinkDns '../../Modules/Microsoft.Network/privateDnsZones/privateDnsZones.bicep' = {
 name: '${name}-File-DNS-Deploy'
 scope: resourceGroup(dnsZoneSubscriptionId, dnsZoneRg)
 params: {
   zoneName: 'privatelink.file.${storageSuffix}'
   createARecord: true
   aRecordName: stroageAccountName
   aRecordIp: storageFilePrivateLink.outputs.customerDnsConfigs[0].ipAddresses[0]
   vnetAssociations: associateDnsZonesWithVNET == true ? [
     {
       id: dnsVnetId
       registrationEnabled: false
     }
   ] : []
 }  
}
