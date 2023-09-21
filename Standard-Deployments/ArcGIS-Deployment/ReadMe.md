# What does this do?
Deploys a standard ArcGis environment:
1. Azure Application Gateway
2. ArcGis Server
3. Portal Server
4. Relational Datastore and Tilecahe
5. Azure Files for SMB

# What does this require?
A valid ArcGis server and portal license in public artifacts location (can be Azure Storage with SAS Token).  Trusted SSL Certificate for App Gateway Public Listener saved in Azure Key Vault.  SSL Certificate for backend server hosting in Azure Key vault.  Root CER that the internal certs are signed as a secret string in the Azure Key Vault.

Currently, a Public DNS record is required that matches the external hostname pointing to the Public IP address of the App Gateway.  Portal will not finish successfully is the record is not in place.  Will be changing this soon.

The DSC Extension Package hosted here uploaded to your artificats location:
[ArcGis-DSC](https://github.com/lukearp/Azure-IAC-Bicep/releases/download/DSC/ArcGis-DSC.zip)

# Parameters
param | type | notes
------|------|------
artifactsLocation | string | public storage location for
dscArchiveFile | string | name of DSC Zip file.  Must be the one provided due to integrations with Azure Key Vault
deploymentPrefix | string | Used for created unique names
location | string | Azure region for deployment
environment | string | AzureCloud or AzureUSGovernment
externalDnsHostName | string | The pulic DNS host name for your ArcGIS Deployment
azureKeyVaultId | string | Key Vault resource ID that has your certificates and secrets
certificateName | string | Name of Certificate in Azure Key Vault
rootCert | string | Name of the Secret that has the internal Root CA Cert saved as a String.  
selfSignedCert | string | Name of Certificate in Azure Key Vault
vnetName | string | Name of the target Virtual Network for App Gateway and VM Deployment
vnetRg | string | VNET Resource Group
subnetName | string | Name of Subnet for VMs
appGatewaySubnetName | string | Name of Subnet for App Gateway
appGatewayName | string | Name of App Gateway
appGatewayResourceGroupName | string | Resource Group for App Gateway
imagePublisher | string | Image publisher for VM, value is 'esri'
imageOffer | string | Image offer for VM, value is 'arcgis-enterprise'
imageSku | string | Image sku, current allowed value is 'byol-110'
adminUsername | string | Local Admin username
adminPassword | string | Local Admin password
serviceUserName | string | Service Account Username/Default Site Username
servicePassword | string | Service Account password/Default Site password
serverVirtualMachineName | string | Name of the Server VM
serverVirtualMachineSize | string | Azure VM Sku for Server
portalVirtualMachineName | string | Name of the Portal VM
portalVirtualMachineSize | string | Azure VM Sku for Portal
dataStoreVirtualMachineName | string | Name of the Datastore/Tilecache VM
dataStoreVirtualMachineSize | string | Azure VM Sku for Datastore/Tilecache
osDiskType | string | Premium or Standard Disk
timeZoneId | string | Time Zone ID, Example: 'Eastern Standard Time'
serverLicenseFileName | string | Name of Server license file that is in your artifacts location
portalLicenseFileName | string | Name of Portal license file that is in your artifacts location
artifactSas | string | If using Azure Blob for artifacts, the SAS token of that artifacts directory.  Needs Object Read
portalLicenseUserTypeId | string | User License ID Type for Portal
certName | string | Name of certificate in Artifacts directory 
tags | object | Azure Resource Manager Tags

# Setup Instructions

1. Accept terms of Esri ArcGIS Images.  Sku Name can be byol-110 for 11.0 and byol-111 for 11.1
```powershell
Set-AzMarketplaceTerms -Publisher esri -Product arcgis-enterprise -Name <skuName> -Accept
```
2. Deploy an Azure Key Vault
```powershell
$keyVault = New-AzKeyVault -Name <keyVaultName> -ResourceGroupName <resourceGroupName> -Location <region> -EnabledForTemplateDeployment -Sku Standard
$secret = Set-AzKeyVaultSecret -VaultName $keyVault.VaultName -Name 'esriStorage' -SecretValue $(ConvertTo-SecureString -String 'hold' -AsPlainText -Force)
$keyVault.Id
```
3. Save the KeyVault ID Output, it will be used as a parameter in the template
4. Add a Publicly Trusted SSL Certificate to the Azure Key Vault's Certificates (PFX), This certificate should have the ExternalDNS name in it's Subject Alternate Names
5. Add a Self Signed Certificate to the Azure Key Vault's Certificates (PFX), This certificate should be a wild card for you Azure Environments Internal DNS Label.  If a VM already exists in your target virtual network, you can run the below script to generate the SelfSigned PFX and RootCA Cert.
```powershell
$vm = Get-AzVM -name <vmname> -resourcegroupname <resourceGroupName>
$nic = Get-AzNetworkInterface -Name $($vm[0].NetworkProfile.NetworkInterfaces[0].Id.Split("/")[8]) -ResourceGroupName $($vm[0].NetworkProfile.NetworkInterfaces[0].Id.Split("/")[4])
$dnsName = "*." + (ConvertFrom-Json -InputObject $nic.DnsSettingsText).InternalDomainNameSuffix
$rootcert = New-SelfSignedCertificate -CertStoreLocation cert:\CurrentUser\My -DnsName "EsriSelfSigned" -KeyUsage CertSign
Export-Certificate -Cert $rootcert -FilePath $(".\EsriSelfSigned.cer")
$cert = New-SelfSignedCertificate -certstorelocation cert:\CurrentUser\My -dnsname $dnsName -Signer $rootcert
$secureString = ConvertTo-SecureString -String "esri" -Force -AsPlainText
Export-PfxCertificate -Cert $cert -Password $secureString -FilePath $(".\esri-selfsigned.pfx") -CryptoAlgorithmOption TripleDES_SHA1
$rootByte = Get-Content $(".\EsriSelfSigned.cer") -AsByteStream
[System.Convert]::ToBase64String($rootByte) | Out-File "RootBase64.txt"
```
6. Add a Secret for the Root CA Cert, Copy the contents of RootBase64.txt and save as a secret in the key vault.
7. Create an Azure Storage Account and Container.
```powershell
$storage = New-AzStorageAccount -Name <storageAccountName> -ResourceGroupName <resourceGroupName> -SkuName Standard_LRS -Location <region> -Kind StorageV2
$artifactsContainer = New-AzStorageContainer -Name "artifacts" -Context $storage.Context
```
8. Copy your Esri Server License File, Portal License File, and the [DSC.zip](https://github.com/lukearp/Azure-IAC-Bicep/releases/tag/DSC) package for your ESRI Version.
9. Generate a SAS Token that will allow us to access the files within the artifacts directory.
```powershell
$storage = Get-AzStorageAccount -Name <storageAccountName> -ResourceGroupName <resourceGroupName>
New-AzStorageAccountSASToken -Service Blob -ResourceType Container,Object -Permission "rl" -ExpiryTime (Get-Date).AddDays(1) -Context $storage.Context | Out-File sasToken.txt
```
10. You should now have all the prerequisets to deploy the template.  

# Example

```bicep
targetScope = 'subscription'

resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: 'argis-bicep'
  location: 'eastus'
  properties: {}  
}

resource keyvault 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: mykeyvault
  scope: keyvault-rg
}

module argis '../../Standard-Deployments/ArcGIS-Deployment/ArcGIS-Deploy.bicep' = {
  name: 'Test-Argis'
  scope: resourceGroup(rg.name)
  params: {
    adminPassword: keyvault.getsecret('adminPass')
    adminUsername: 'localadmin'
    appGatewayName: 'esriappgw' 
    appGatewayResourceGroupName: 'luke-arcgis-test' 
    appGatewaySubnetName: 'appgw' 
    vnetName: 'gis'
    vnetRg: 'luke-arcgis-test' 
    azureKeyVaultId: '/subscriptions/32eb88b4-4029-4094-85e3-ec8b7ce1fc00/resourceGroups/keyvault/providers/Microsoft.KeyVault/vaults/luke-keyvault-enterprise'
    certificateName: 'wildcard-lukesprojects-com5d8c74b1-780e-437a-8624-f5483ed800f1'
    dataStoreVirtualMachineName: 'datastore'
    deploymentPrefix: 'gis1'
    dscArchiveFile: 'DSC.zip'
    externalDnsHostName: 'lukeesri.mytest.com'
    location: 'eastus'
    portalVirtualMachineName: 'portal'
    serverVirtualMachineName: 'server'
    subnetName: 'default' 
    rootCert: 'root-ca'
    selfSignedCert: 'esri-selfsigned'
    serverLicenseFileName: 'ArcGISGISServerAdvanced_ArcGISServer_XXXX.prvc'
    portalLicenseFileName: 'ArcGIS_Enterprise_Portal_XXXXX.json'
    artifactSas: keyvault.getsecret('artifactSas')
    artifactsLocation: 'https://mystorage.blob.core.windows.net/bicep'
    serviceUserName: 'gis'
    servicePassword: keyvault.getsecret('servicePass')  
    certName: 'mycert.pfx' 
  }  
}
```
