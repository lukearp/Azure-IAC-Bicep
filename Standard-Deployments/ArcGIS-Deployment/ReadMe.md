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
[ArcGis-DSC](https://github.com/lukearp/Azure-IAC-Bicep/releases)

# Parameters (ADVANCED DEPLOY)
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

# Setup Instructions (LEGACY)

Get User Object ID in Azure Cloud Shell:
Connect-AzAccount -UseDeviceAuthentication;(Get-AzADUser -ObjectId ((get-AzContext).Account).Id).Id;

The following steps can be performed in the [Azure Cloud Shell](https://learn.microsoft.com/en-us/azure/cloud-shell/quickstart?tabs=powershell) or your local machine if you have the Powershell Modules installed:
```powershell
Install-Module -Name Az
```
The script snippets given in Step 6 will not work in the Azure Cloud Shell due to not having access to the New-SelfSignedCertificate commandlet.  Those tasks will need to be performed on your own machine, or you can use other means of generating the certificates.  

1. Accept terms of Esri ArcGIS Images.  Sku Name can be byol-110 for 11.0 and byol-111 for 11.1
```powershell
Set-AzMarketplaceTerms -Publisher esri -Product arcgis-enterprise -Name <skuName> -Accept
```
2. Deploy an [Azure Key Vault](https://learn.microsoft.com/en-us/azure/key-vault/general/quick-create-portal) with a secret called esriStorage.  The esriStorage secret is what we use to store the Storage Account Key for the SMB connections. This secret must be present if you are using an existing Keyvault.  If you are creating a new Key Vault in the Azure Portal, be sure to enable Azure Resource Manager for template deployment.  
```powershell
Select-AzSubscription <subscriptionId>
$keyVault = New-AzKeyVault -Name <keyVaultName> -ResourceGroupName <resourceGroupName> -Location <region> -EnabledForTemplateDeployment -Sku Standard
$secret = Set-AzKeyVaultSecret -VaultName $keyVault.VaultName -Name 'esriStorage' -SecretValue $(ConvertTo-SecureString -String 'hold' -AsPlainText -Force)
$keyVault.ResourceId | Out-File .\keyVaultResourceId.txt
```
3. Add user that will be deploying the Template to the Key Vault Access Policy.  The user will need Secret Get, List, Set and Certificate Get, List, Create, Import
4. Save the KeyVault ID Output, it will be used as a parameter in the template.
5. [Add a Publicly Trusted SSL Certificate to the Azure Key Vault's Certificates (PFX)](https://learn.microsoft.com/en-us/azure/key-vault/certificates/tutorial-import-certificate?tabs=azure-portal), This certificate should have the ExternalDNS name in it's Subject Alternate Name or be a wildcard certificate for the domain suffix.
6. [Add a Self Signed Certificate to the Azure Key Vault's Certificates (PFX)](https://learn.microsoft.com/en-us/azure/key-vault/certificates/tutorial-import-certificate?tabs=azure-portal), This certificate should be a wild card for you Azure Environments Internal DNS Label.  If a VM already exists in your target virtual network, you can run the below script to generate the SelfSigned PFX and RootCA Cert.  If you do not have a VM in the target VNET, you will need to deploy one in order to get the DNS Suffix of that VNET.
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
7. [Add a Secret for the Root CA Cert](https://learn.microsoft.com/en-us/azure/key-vault/secrets/quick-create-portal). If you used the commands above, you can copy the contents of RootBase64.txt and save as a secret in the key vault.  If not, just convert your Root CA file into a single line base64 string.
8. [Create an Azure Storage Account](https://learn.microsoft.com/en-us/azure/storage/common/storage-account-create?tabs=azure-portal) and [Container](https://learn.microsoft.com/en-us/azure/storage/blobs/storage-quickstart-blobs-portal#create-a-container).  A Blob or General Purpose v2 and Standard LRS account is fine.  This will just be used to store the artifacts needed to configure ArcGIS
```powershell
$storage = New-AzStorageAccount -Name <storageAccountName> -ResourceGroupName <resourceGroupName> -SkuName Standard_LRS -Location <region> -Kind StorageV2
$artifactsContainer = New-AzStorageContainer -Name "artifacts" -Context $storage.Context
```
9. [Upload](https://learn.microsoft.com/en-us/azure/storage/blobs/storage-quickstart-blobs-portal#upload-a-block-blob) your Esri Server License File, Portal License File, and the [DSC.zip](https://github.com/lukearp/Azure-IAC-Bicep/releases/tag/DSC) package for your ESRI Version.
10. Generate a SAS Token that will allow us to access the files within the artifacts directory.
```powershell
$storage = Get-AzStorageAccount -Name <storageAccountName> -ResourceGroupName <resourceGroupName>
New-AzStorageAccountSASToken -Service Blob -ResourceType Container,Object -Permission "rl" -ExpiryTime (Get-Date).AddDays(1) -Context $storage.Context | Out-File sasToken.txt
```
11. You should now have all the prerequisets to deploy the template. You can download the [latest built JSON here](https://github.com/lukearp/Azure-IAC-Bicep/releases/download/DSC/ArcGIS-Deploy.json) and [Deploy a custom template](https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/quickstart-create-templates-use-the-portal) in the portal. 

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
    azureKeyVaultId: '/subscriptions/XXX-XX-XXXXXX/resourceGroups/keyvault/providers/Microsoft.KeyVault/vaults/kv-test'
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
