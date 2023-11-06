param vmName string
param location string
param artifactsLocation string
param artifactSas string
param dscArchiveFile string
param portalLicenseFile string
param portalLicenseType string
param serviceUserName string
@secure()
param servicePassword string
@secure()
param selfsignedCertData string
@secure()
param ssroot string
param externalDnsHostName string
param storageAccountName string
@secure()
param storageKey string
param storageSuffix string
param serverName string

var dscUrl = length(split(dscArchiveFile,'/')) > 0 ? dscArchiveFile : '${artifactsLocation}/${dscArchiveFile}${artifactSas}'

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
        function: 'PortalConfiguration'
        script: 'PortalConfiguration.ps1'
      }
      configurationArguments: {
        ServiceCredentialIsDomainAccount: false
        PortalLicenseFileUrl: '${artifactsLocation}/${portalLicenseFile}${artifactSas}'
        PortalLicenseUserTypeId: portalLicenseType
        ServerMachineNames: serverName
        PortalMachineNames: vmName
        FileShareName: 'esri'
        ExternalDNSHostName: externalDnsHostName
        UseCloudStorage: 'True'
        UseAzureFiles: 'True'
        ServerContext: 'server'
        PortalContext: 'portal'
        FileShareMachineName: 'Test'
        OSDiskSize: 128
        EnableDataDisk: 'False'
      }
    }
    protectedSettings: {
      configurationArguments: {
        PortalInternalCertificateData: selfsignedCertData
        rootCertificateData: ssroot
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
        PortalInternalCertificatePassword: {
          userName: 'Placeholder'
          password: '12345'
        }
      }
    }
  }
}
