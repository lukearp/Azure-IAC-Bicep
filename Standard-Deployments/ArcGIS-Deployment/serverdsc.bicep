param vmName string
param location string
param artifactsLocation string
param artifactSas string
param dscArchiveFile string
param serverLicenseFile string
param serviceUserName string
@secure()
param servicePassword string
//@secure()
//param selfsignedCertData string
param externalDnsHostName string
param storageAccountName string
@secure()
param storageKey string
param storageSuffix string
param networkInterfaceId string
param keyVaultName string
param cloudEnvironment string
//param certName string

var dscUrl = length(split(dscArchiveFile,'/')) > 0 ? dscArchiveFile : '${artifactsLocation}/${dscArchiveFile}${artifactSas}'
var internalWildcard = '*.${reference(networkInterfaceId, '2023-04-01', 'FULL').properties.dnsSettings.internalDomainNameSuffix}'

resource serverDsc 'Microsoft.Compute/virtualMachines/extensions@2023-03-01' = {
  name: '${vmName}/DSCConfiguration'
  location: location
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.77'
    autoUpgradeMinorVersion: true
    settings: {
      wmfVersion: 'latest'
      configuration: {
        url: dscUrl
        function: 'ServerConfiguration'
        script: 'ServerConfiguration.ps1'
      }
      configurationArguments: {
        ServiceCredentialIsDomainAccount: false
        InternalDnsName: internalWildcard
        azureCloud: cloudEnvironment
        keyVaultName: keyVaultName
        //PublicKeySSLCertificateFileUrl: '${artifactsLocation}/${certName}${artifactSas}'
        ServerLicenseFileUrl: '${artifactsLocation}/${serverLicenseFile}${artifactSas}'
        ServerMachineNames: vmName
        FileShareName: 'esri'
        ExternalDNSHostName: externalDnsHostName
        UseCloudStorage: true
        UseAzureFiles: true
        EnableLogHarvesterPlugin: false
        ServerContext: 'server'
        FileShareMachineName: 'Test'
        OSDiskSize: 128
        EnableDataDisk: false
        DebugMode: true
      }
    }
    protectedSettings: {
      configurationArguments: {
      //  ServerInternalCertificateData: selfsignedCertData
      //  certPassword: certPass
        StorageAccountCredential: {
          userName: '${storageAccountName}.${storageSuffix}'
          password: storageKey
        }
        SiteAdministratorCredential: {
          userName: serviceUserName
          password: servicePassword
        }
        ServiceCredential: {
          userName: serviceUserName
          password: servicePassword
        }
        ServerInternalCertificatePassword: {
          userName: 'Placeholder'
          password: '12345'
        }
      }
    }
  }
}
