param deploymentRgName string
param artifactsLocation string = ''
param dscArchiveFile string
param deploymentPrefix string
param location string
@allowed([
  'AzureCloud'
  'AzureUSGovernment'
])
param environment string = 'AzureCloud'
@description('DNS name for the site deployment. It will be a custom domain (e.g. mysite.contoso.com) if using a Private IP or an SSL certificate, otherwise will be the Azure DNS <dnsPrefixForPublicIpAddress>.<location>.cloudapp.azure.com')
param externalDnsHostName string
@description('Resource ID of Azure Key Vault')
param azureKeyVaultId string
@description('Certificate Name in Azure Key Vault')
param certificateName string
param rootCert string
param selfSignedCert string
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
/*@description('ArcGIS Image Info')
param imageReferences object = {
  '0': {
    Publisher: 'esri'
    Offer: 'arcgis-enterprise'
    SKU: 'byol-110'
    AzureVMImageType: 0
  }
}*/
@allowed([
  'esri'
])
param imagePublisher string = 'esri'
@allowed([
  'arcgis-enterprise'
])
param imageOffer string = 'arcgis-enterprise'
param imageSku string = 'byol-110'
@description('Administrator username')
param adminUsername string
@description('Secure String Password, No special characters')
@secure()
param adminPassword string
param serviceUserName string
@secure()
param servicePassword string
param serverVirtualMachineName string
param serverVirtualMachineSize string = 'Standard_DS3_v2'
param portalVirtualMachineName string
param portalVirtualMachineSize string = 'Standard_DS3_v2'
param dataStoreVirtualMachineName string
param dataStoreVirtualMachineSize string = 'Standard_DS3_v2'
@allowed([
  'Premium_LRS'
  'Standard_LRS'
  'StandardSSD_LRS'
])
param osDiskType string = 'Premium_LRS'
param timeZoneId string = 'Eastern Standard Time'
//param joinWindowsDomain bool = false
//param windowsDomainName string
//param joinDomainAccountUsername string
//@secure()
//param joinDomainAccountPassword string
//param arcgisServiceAccountIsDomainAccount bool = false
param serverLicenseFileName string
param portalLicenseFileName string
param artifactSas string
param portalLicenseUserTypeId string = 'creatorUT'
param tags object = {}

var storageSuffix = environment == 'AzureCloud' ? 'blob.core.windows.net' : 'blob.core.usgovcloudapi.net'

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
    generateSas: true
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

module appGateway 'esri-appgw.bicep' = {
  name: 'AppGatewayDeployment'
  scope: resourceGroup(appGatewayResourceGroupName)
  params: {
    rootCert: keyvault.getSecret(rootCert)
    portalNicId: portal.outputs.networkInterfaceId
    serverNicId: server.outputs.networkInterfaceId
    serverVirtualMachineName: serverVirtualMachineName
    portalVirtualMachineName: portalVirtualMachineName
    location: 'eastus'
    autoScaleMax: 10
    skuName: 'Standard_v2'
    enableHttp2: false
    name: appGatewayName
    subnetName: appGatewaySubnetName
    virtualnetwork: vnetName
    virtualnetworkRg: vnetRg
    autoScaleMin: 0
    publicCertString: keyvault.getSecret(certificateName)  
    externalDnsHostName: externalDnsHostName
  }
  dependsOn: [
    server
    portal
  ]
}

module server '../../Modules/Microsoft.Compute/virtualMachines/virtualMachines.bicep' = {
  name: 'Server-Deploy'
  params: {
    adminPassword: adminPassword
    adminUsername: adminUsername
    imageOffer: imageOffer
    imageSku: imageSku
    imagePublisher: imagePublisher
    location: location
    name: serverVirtualMachineName
    serverVirtualMachineOSDiskType: osDiskType
    vmSize: serverVirtualMachineSize
    subnetName: subnetName
    vnetName: vnetName
    vnetRg: vnetRg
    timeZoneId: timeZoneId
    tags: tags
  }
}

module serverDsc 'serverdsc.bicep' = {
  name: 'Server-DSC-Setup'
  dependsOn: [
    server
    share
  ]
  params: {
    artifactsLocation: artifactsLocation
    artifactSas: artifactSas
    deploymentPrefix: deploymentPrefix
    dscArchiveFile: dscArchiveFile
    externalDnsHostName: externalDnsHostName
    location: location
    serverLicenseFile: serverLicenseFileName
    selfsignedCertData: keyvault.getSecret(selfSignedCert)
    storageKey: keyvault.getSecret('esriStorage')
    vmName: serverVirtualMachineName
    serviceUserName: serviceUserName
    servicePassword: servicePassword 
    storageSuffix: storageSuffix           
  }
}

module portal '../../Modules/Microsoft.Compute/virtualMachines/virtualMachines.bicep' = {
  name: 'Portal-Deploy'
  params: {
    adminPassword: adminPassword
    adminUsername: adminUsername
    imageOffer: imageOffer
    imageSku: imageSku
    imagePublisher: imagePublisher
    location: location
    name: portalVirtualMachineName
    serverVirtualMachineOSDiskType: osDiskType
    vmSize: portalVirtualMachineSize
    subnetName: subnetName
    vnetName: vnetName
    vnetRg: vnetRg
    timeZoneId: timeZoneId
    tags: tags
  }
}

module portalDsc 'portaldsc.bicep' = {
  name: 'Portal-Setup-Deploy'
  dependsOn: [
    serverDsc
    dataDsc
    portal
  ]
  params: {
    artifactSas: artifactSas
    artifactsLocation: artifactsLocation
    deploymentPrefix: deploymentPrefix
    dscArchiveFile: dscArchiveFile
    externalDnsHostName: externalDnsHostName
    location: location
    portalLicenseFile: portalLicenseFileName
    portalLicenseType: portalLicenseUserTypeId
    selfsignedCertData: keyvault.getSecret(selfSignedCert)
    serverName: serverVirtualMachineName
    vmName: portalVirtualMachineName
    servicePassword: servicePassword
    serviceUserName: serviceUserName
    storageKey: keyvault.getSecret('esriStorage')
    storageSuffix: storageSuffix           
  }
}

module data '../../Modules/Microsoft.Compute/virtualMachines/virtualMachines.bicep' = {
  name: 'Data-Deploy'
  params: {
    adminPassword: adminPassword
    adminUsername: adminUsername
    imageOffer: imageOffer
    imageSku: imageSku
    imagePublisher: imagePublisher
    location: location
    name: dataStoreVirtualMachineName
    serverVirtualMachineOSDiskType: osDiskType
    vmSize: dataStoreVirtualMachineSize
    subnetName: subnetName
    vnetName: vnetName
    vnetRg: vnetRg
    timeZoneId: timeZoneId
    tags: tags
  }
}

module dataDsc 'datadsc.bicep' = {
  name: 'Data-DSC-Setup'
  dependsOn: [
    serverDsc
    data
  ]
  params: {
    artifactSas: artifactSas
    artifactsLocation: artifactsLocation
    deploymentPrefix: deploymentPrefix
    dscArchiveFile: dscArchiveFile
    externalDnsHostName: externalDnsHostName
    location: location
    serverName: serverVirtualMachineName 
    servicePassword: servicePassword
    serviceUserName: serviceUserName
    storageKey: keyvault.getSecret('esriStorage')
    vmName: dataStoreVirtualMachineName 
    storageSuffix: storageSuffix        
  }
}

resource keyvault 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: split(azureKeyVaultId, '/')[8]
  scope: resourceGroup(split(azureKeyVaultId, '/')[2], split(azureKeyVaultId, '/')[4])
}

/*module serverDsc 'dsc.bicep' = {
  name: '${serverVirtualMachineName}-DSC'
  params: {
    _artifactsLocation: _artifactsLocation
    artifactSas: storageAccount.outputs.sas
    portalLicenseFile: ''
    serverLicenseFile: ''
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
}*/
