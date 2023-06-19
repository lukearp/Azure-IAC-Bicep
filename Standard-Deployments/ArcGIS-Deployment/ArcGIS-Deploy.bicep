param deploymentRgName string
param _artifactsLocation string = ''
param dscArchiveFile string
param deploymentPrefix string
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
@description('Resource ID of Azure Key Vault')
param azureKeyVaultId string
@description('Certificate Name in Azure Key Vault')
param certificateName string
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
param imagePublisher string = 'esri'
param imageOffer string = 'arcgis-enterprise'
param imageSku string = 'byol-110'
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
param tags object = {}

module storageAccount '../../Modules/Microsoft.Storage/storageAccounts/storageAccounts.bicep' = {
  name: '${deploymentPrefix}-StorageAccount'
  params: {
    kind: 'StorageV2'
    location: location
    name: substring('${deploymentPrefix}${replace(guid(subscription().id, resourceGroup().name, location), '-', '')}', 0, 23)
    sku: 'Standard_LRS'
    storeKeysInKeyVault: true
    keyVaultName: split(azureKeyVaultId, '/')[8]
    keyVaultRg: split(azureKeyVaultId, '/')[4]
    secretName: 'esriStorage'
    tags: tags
  }
}

module share '../../Modules/Microsoft.Storage/storageAccounts/share/share.bicep' = {
  name: '${deploymentPrefix}-Share'
  params: {
    shareName: 'esri'
    storageAccountName: split(storageAccount.outputs.storageAccountId, '/')[8]
  }
}

module appGatewayPip '../../Modules/Microsoft.Network/publicIpAddresses/publicIpAddresses.bicep' = {
  name: 'AppGateway-PublicIP'
  params: {
    name: 'Esri-AppGW-PIP'
    location: location
    publicIpAllocationMethod: 'Static'
    sku: 'Standard'
    publicIpAddressVersion: 'IPv4'
    tier: 'Regional'
    tags: tags
  }
}

module vm '../../Modules/Microsoft.Compute/virtualMachines/virtualMachines.bicep' = {
  name: 'VM-Deploy-Test'
  params: {
    adminPassword: adminPassword
    adminUsername: adminUsername
    imageOffer: imageOffer
    imageSku: imageSku
    imagePublisher: imagePublisher
    location: location
    name: serverVirtualMachineName
    serverVirtualMachineOSDiskType: serverVirtualMachineOSDiskType
    vmSize: serverVirtualMachineSize
    subnetName: subnetName
    vnetName: vnetName
    vnetRg: vnetRg
    timeZoneId: timeZoneId
    tags: tags
  }
}

resource keyvault 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: split(azureKeyVaultId,'/')[8]
  scope: resourceGroup(split(azureKeyVaultId,'/')[2],split(azureKeyVaultId,'/')[4]) 
}

module serverDsc 'dsc.bicep' = {
  name: '${serverVirtualMachineName}-DSC'
  params: {
    _artifactsLocation: _artifactsLocation
    vmName: serverVirtualMachineName
    adminUsername: adminUsername
    stroageKey: keyvault.getSecret('esriStorage')
    deploymentPrefix: deploymentPrefix
    dscArchiveFile: dscArchiveFile
    externalDnsHostName: externalDnsHostName
    location: location    
    selfSignedSSLCertificatePassword: '1234' 
    adminPassword: adminPassword    
  }   
}
