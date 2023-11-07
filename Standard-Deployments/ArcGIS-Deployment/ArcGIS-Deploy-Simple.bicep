//param deploymentRgName string
@description('Prefix name for deployment objects')
param deploymentPrefix string = 'esri'
@description('User Object ID that is deploying the ARM Template.  This is for KeyVault RBAC Assignment')
param userObjectId string
@description('Azure Region to deploy. Example: eastus')
param AzureRegion string
@allowed([
  'AzureCloud'
  'AzureUSGovernment'
])
@description('Cloud to deploy in.')
param cloudEnvironment string = 'AzureCloud'
@description('DNS name for the site deployment. It will be a custom domain (e.g. mysite.contoso.com) if using a Private IP or an SSL certificate, otherwise will be the Azure DNS <dnsPrefixForPublicIpAddress>.<location>.cloudapp.azure.com')
param externalDnsHostName string
@description('Resource ID of Azure Key Vault')
@allowed([
  'esri'
])
param imagePublisher string = 'esri'
@allowed([
  'arcgis-enterprise'
])
param imageOffer string = 'arcgis-enterprise'
@allowed([
  'byol-111'
])
param imageSku string = 'byol-111'
@description('Server VM Name')
param serverVirtualMachineName string
//@description('Server VM Instance Size')
//param serverVirtualMachineSize string = 'Standard_DS3_v2'
@description('Portal VM Name')
param portalVirtualMachineName string
// @description('Portal VM Instance Size')
// param portalVirtualMachineSize string = 'Standard_DS3_v2'
@description('Datastore/Tilecache VM Name')
param dataStoreVirtualMachineName string
// @description('Datastore/Tilecache VM Instance Size')
// param dataStoreVirtualMachineSize string = 'Standard_DS3_v2'
param osDiskType string = 'Premium_LRS'
@description('Time Zone ID')
@allowed([
  'Eastern Standard Time'
  'Central Standard Time'
  'Mountain Standard Time'
  'Pacific Standard Time'
])
param timeZoneId string = 'Eastern Standard Time'
//param joinWindowsDomain bool = false
//param windowsDomainName string
//param joinDomainAccountUsername string
//@secure()
//param joinDomainAccountPassword string
//param arcgisServiceAccountIsDomainAccount bool = false
@description('Name of Server License File in your Artifacts location')
param serverLicenseFileName string
@description('Name of Portal License File in your Artifacts location')
param portalLicenseFileName string
//@description('Name of PFX in Artifacts Location')
//param certName string
@description('Storage Account Container path with License Files')
param artifactsLocation string = ''
@description('SAS Token if Artificats location is in blob storage')
param artifactSas string
// @description('Portal License User Type ID')
// param portalLicenseUserTypeId string = 'creatorUT'
@description('Azure Resource Tags')
param tags object = {}

var storageSuffix = cloudEnvironment == 'AzureCloud' ? 'blob.core.windows.net' : 'blob.core.usgovcloudapi.net'
var portalLicenseUserTypeId = 'creatorUT'
var keyVaultName = substring('KV-${replace(guid(subscription().id, resourceGroup().name, AzureRegion), '-', '')}', 0, 15)
var dscArchiveFile = 'https://github.com/lukearp/Azure-IAC-Bicep/releases/download/DSC/ArcGIS-DSC-11.1.zip'
var virtualMachineSize = 'Standard_D4ads_v5'
var adminUsername = 'localadmin'
var serviceUserName = 'gis'
var vnetName = substring('VN-${replace(guid(subscription().id, resourceGroup().name, AzureRegion), '-', '')}', 0, 15)
var appGatewayName = 'AppGW-Esri'

module keyVault 'keyvault.bicep' = {
  name: 'KeyVault-Deploy'
  params: {
    deploymentPrefix: deploymentPrefix
    keyVaultName: keyVaultName
    location: AzureRegion
    userObjectId: userObjectId    
  } 
}

module arcGisCore 'arcgis-root.bicep' = {
  name: 'Core-ArcGis-Deploy'
  params: {
    adminPassword: keyVault.outputs.adminPasswordName
    adminUsername: adminUsername
    appGatewayName: appGatewayName
    artifactSas: artifactSas
    artifactsLocation: artifactsLocation
    dataStoreVirtualMachineName: dataStoreVirtualMachineName
    deploymentPrefix: deploymentPrefix
    dscArchiveFile: dscArchiveFile
    externalCertName: keyVault.outputs.externalName
    externalDnsHostName: externalDnsHostName
    imageOffer: imageOffer
    imagePublisher: imagePublisher
    imageSku: imageSku
    internalCertName: keyVault.outputs.internalName
    keyVaultName: keyVaultName
    location: AzureRegion
    osDiskType: osDiskType
    portalLicenseFileName: portalLicenseFileName
    portalLicenseUserTypeId: portalLicenseUserTypeId
    portalVirtualMachineName: portalVirtualMachineName
    rootCertName: keyVault.outputs.rootCertName
    serverLicenseFileName: serverLicenseFileName
    serverVirtualMachineName: serverVirtualMachineName
    servicePassword: keyVault.outputs.servicePasswordName
    serviceUserName: serviceUserName
    storageKeyName: keyVault.outputs.storageKeyName
    storageSuffix: storageSuffix
    timeZoneId: timeZoneId
    virtualMachineSize: virtualMachineSize
    vnetName: vnetName
    cloudEnvironment: cloudEnvironment
    tags: tags                             
  } 
}
