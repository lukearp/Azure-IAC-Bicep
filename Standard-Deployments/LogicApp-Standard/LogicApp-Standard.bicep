param name string
param location string
param azureGov bool = false
param existingAppServicePlan bool = false
@allowed([
  'WS1'
  'WS2'
  'WS3'
  'I1V2'
  'I2V2'
  'I3V2'
])
param appPlanSize string = 'WS1'
param aseId string = ''
param existingAppServicePlanId string = ''
param enableVNETIntegration bool = false
param logicAppVNETSubnetId string = ''
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
var logicAppVnetResourceGroup = logicAppVNETSubnetId == '' ? resourceGroup().name : split(logicAppVNETSubnetId,'/')[4] 
var appPlanTier = aseId != '' && (appPlanSize == 'WS1' || appPlanSize == 'WS2' || appPlanSize == 'WS3') ? 'I1V2' : appPlanSize

module appPlan '../../Modules/Microsoft.Web/serverFarms/serverFarms-StandardLogicApps.bicep' = if(existingAppServicePlan == false) {
  name: '${name}-Plan-Deploy' 
  params: {
     name: '${name}-Plan'
     location: location
     skuName: appPlanTier
     aseId: aseId 
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

module getSubnetProperties 'subnetProperties.bicep' = if(enableVNETIntegration == true){
  name: 'Get-Subnet-Properties'
  scope: resourceGroup(logicAppVnetResourceGroup)
  params: {
    subnetId: logicAppVNETSubnetId 
  }   
}


module logicApp '../../Modules/Microsoft.Web/sites/sites-logicapp.bicep' = {
  name: '${name}-LogicApp-Deploy'
  params: {
    appServicePlanId: existingAppServicePlan == false ? appPlan.outputs.planId : existingAppServicePlanId
    location: location
    name: name
    storageAccountConnectionString: 'DefaultEndpointsProtocol=https;AccountName=la${nameSuffix};AccountKey=${storageAccount.listKeys().keys[0].value};EndpointSuffix=${storageSuffix}' 
    logicAppVNETSubnetId: enableVNETIntegration == false ? '' : logicAppVNETSubnetId
    publicNetworkAccessEnabled: enablePrivateLink == true && aseId == '' ? publicNetworkAccessEnabled == true ? 'Enabled' : 'Disabled' : 'Enabled' 
    tags: tags    
  }
  dependsOn: [
    getSubnetProperties
  ]
}

module privateLink 'privateLink.bicep' = if(enablePrivateLink == true) {
  name: '${name}-Private-Link-Deploy'
  params: {
    associateDnsZonesWithVNET: associateDnsZonesWithVNET
    azureGov: azureGov
    dnsVnetId: dnsVnetId
    dnsZoneRg: dnsZoneRg
    dnsZoneSubscriptionId: dnsZoneSubscriptionId
    location: location
    logicAppResourceId: logicApp.outputs.resourceId
    name: name
    privateLinkSubnetId: privateLinkSubnetId
    storageAccountResourceId: storageAccount.id
    aseId: aseId
    tags: tags            
  }  
}
