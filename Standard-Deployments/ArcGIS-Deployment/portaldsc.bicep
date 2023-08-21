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
param externalDnsHostName string
param deploymentPrefix string
@secure()
param storageKey string
param storageSuffix string
param serverName string
param certName string
@secure()
param rootCertData string
param serverNicId string

var serverIntDomain = '${serverName}.${reference(serverNicId, '2023-04-01', 'FULL').properties.dnsSettings.internalDomainNameSuffix}'

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
        url: '${artifactsLocation}/${dscArchiveFile}${artifactSas}'
        function: 'PortalConfiguration'
        script: 'PortalConfiguration.ps1'
      }
      configurationArguments: {
        ServiceCredentialIsDomainAccount: false
        PublicKeySSLCertificateFileUrl: '${artifactsLocation}/${certName}${artifactSas}'
        PrivateDNSHostName: serverIntDomain
        PortalLicenseFileUrl: '${artifactsLocation}/${portalLicenseFile}${artifactSas}'
        PortalLicenseUserTypeId: portalLicenseType
        ServerMachineNames: serverName
        PortalMachineNames: vmName
        FileShareName: 'esri'
        ExternalDNSHostName: externalDnsHostName
        UseCloudStorage: true
        UseAzureFiles: true
        ServerContext: 'server'
        PortalContext: 'portal'
        FileShareMachineName: 'Test'
        OSDiskSize: 128
        EnableDataDisk: false
        DebugMode: true
      }
    }
    protectedSettings: {
      configurationArguments: {
        PortalInternalCertificateData: selfsignedCertData
        RootInternalCertificateData: rootCertData
      //  certPassword: certPass
        StorageAccountCredential: {
          userName: '${substring('${deploymentPrefix}${replace(guid(subscription().id, resourceGroup().name, location), '-', '')}', 0, 23)}.${storageSuffix}'
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
