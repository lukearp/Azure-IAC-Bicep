param _artifactsLocation string = ''
param location string
@allowed([
  'AzureCloud'
  'AzureUSGovernment'
])
param environment string = 'AzureCloud'
@description('DNS name for the Public IP address resource asociated with the site deployment. It needs to be unique across the region of deployment')
param dnsPrefixForPublicIpAddress string
@description('DNS name for the site deployment. It will be a custom domain (e.g. mysite.contoso.com) if using a Private IP or an SSL certificate, otherwise will be the Azure DNS <dnsPrefixForPublicIpAddress>.<location>.cloudapp.azure.com')
param externalDnsHostName string
@description('Resource ID of Certificate in Azure Key Vault')
param certificateId string
@description('Existing VNET Resource Group')
param vnetRg string
@description('Name of Existing VNET')
param vnetName string
@description('Target Subnet for deployment')
param subnetName string
@description('App Gateway Subnet')
param appGatewaySubnetName string
@description('Name of App Gateway')
param appGatewayName string
@description('Resource Group name for App Gateway')
param appGatewayResourceGroupName string
@description('ArcGIS Image Info')
param imageReferences object = {
  '0': {
    Publisher: 'esri'
    Offer: 'arcgis-enterprise'
    SKU: 'byol-110'
    AzureVMImageType: 0
  }
}
@description('Administrator username')
param adminUsername string
@description('Secure String Password, No special characters')
@secure()
param adminPassword string
param serverVirtualMachineName string
param serverVirtualMachineSize string = 'Standard_DS3_v2'
@allowed([
  'Premium_LRS'
  'Standard_LRS'
  'StandardSSD_LRS'
])
param serverVirtualMachineOSDiskType string = 'Premium_LRS'
param portalVirtualMachineName string
param portalVirtualMachineSize string = 'Standard_DS3_v2'
@allowed([
  'Premium_LRS'
  'Standard_LRS'
  'StandardSSD_LRS'
])
param portalVirtualMachineOSDiskType string = 'Premium_LRS'
param dataStoreVirtualMachineName string
param dataStoreVirtualMachineSize string = 'Standard_DS3_v2'
@allowed([
  'Premium_LRS'
  'Standard_LRS'
  'StandardSSD_LRS'
])
param dataStoreVirtualMachineOSDiskType string = 'Premium_LRS'
param timeZoneId string = 'Eastern Standard Time'
param joinWindowsDomain bool = false
param windowsDomainName string
param joinDomainAccountUsername string
@secure()
param joinDomainAccountPassword string
param arcgisServiceAccountIsDomainAccount bool = false
param serverLicenseFileName string
param portalLicenseFileName string
param portalLicenseUserTypeId string = 'creatorUT'

var environmentToBlobEndpoint = {
  AzureCloud: '.blob.core.windows.net'
  AzureGermanCloud: '.blob.core.cloudapi.de'
  AzureUSGovernment: '.blob.core.usgovcloudapi.net'
  AzureChinaCloud: '.blob.core.chinacloudapi.cn'
}
