param vmName string
param serverName string
param location string
param artifactsLocation string
param artifactSas string
param dscArchiveFile string
param externalDnsHostName string
param serviceUserName string
@secure()
param servicePassword string
param deploymentPrefix string
@secure()
param storageKey string
param storageSuffix string

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
        function: 'DataStoreConfiguration'
        script: 'DataStoreConfiguration.ps1'
      }
      configurationArguments: {
        ServiceCredentialIsDomainAccount: false
        DataStoreMachineNames: vmName
        FileShareName: 'esri'
        ServerMachineNames: serverName        
        ExternalDNSHostName: externalDnsHostName
        UseCloudStorage: true
        UseAzureFiles: true
        FileShareMachineName: 'Test'
        OSDiskSize: 128
        EnableDataDisk: false
        DebugMode: true
      }
    }
    protectedSettings: {
      configurationArguments: {
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
      }
    }
  }
}
