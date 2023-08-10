//param deploymentRgName string
param artifactsLocation string = ''
@description('Name of ZIP file for DCS package')
param dscArchiveFile string
@description('String used to radmonize naming')
param deploymentPrefix string
@description('Azure Region to deploy')
param location string
@allowed([
  'AzureCloud'
  'AzureUSGovernment'
])
@description('Cloud to deploy in.')
param environment string = 'AzureCloud'
@description('DNS name for the site deployment. It will be a custom domain (e.g. mysite.contoso.com) if using a Private IP or an SSL certificate, otherwise will be the Azure DNS <dnsPrefixForPublicIpAddress>.<location>.cloudapp.azure.com')
param externalDnsHostName string
@description('Resource ID of Azure Key Vault')
param azureKeyVaultId string
@description('Certificate Name in Azure Key Vault')
param certificateName string
@description('Secret holding the Root CA Cert as a Base64 String')
param rootCert string
@description('Certificate name in Azure Key Vault for backend comminucations')
param selfSignedCert string
@description('Existing VNET Resource Group')
param vnetRg string
@description('Name of Existing VNET')
param vnetName string
@description('Target Subnet for VM deployment')
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
@allowed([
  'byol-110'
])
param imageSku string = 'byol-110'
@description('Administrator username')
param adminUsername string
@description('Secure String Password, No special characters')
@secure()
param adminPassword string
@description('Service/Default Site Username')
param serviceUserName string
@secure()
@description('Service/Default Site Password')
param servicePassword string
@description('Server VM Name')
param serverVirtualMachineName string
@description('Server VM Instance Size')
param serverVirtualMachineSize string = 'Standard_DS3_v2'
@description('Portal VM Name')
param portalVirtualMachineName string
@description('Portal VM Instance Size')
param portalVirtualMachineSize string = 'Standard_DS3_v2'
@description('Datastore/Tilecache VM Name')
param dataStoreVirtualMachineName string
@description('Datastore/Tilecache VM Instance Size')
param dataStoreVirtualMachineSize string = 'Standard_DS3_v2'
@allowed([
  'Premium_LRS'
  'Standard_LRS'
  'StandardSSD_LRS'
])
@description('OS Disk Sku')
param osDiskType string = 'Premium_LRS'
@description('Time Zone ID')
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
@description('Name of PFX in Artifacts Location')
param certName string
@description('SAS Token if Artificats location is in blob storage')
param artifactSas string
@description('Portal License User Type ID')
param portalLicenseUserTypeId string = 'creatorUT'
@description('Azure Resource Tags')
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
    certName: certName         
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
    certName: certName          
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
