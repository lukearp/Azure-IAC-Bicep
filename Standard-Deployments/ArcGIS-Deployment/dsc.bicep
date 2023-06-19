param vmName string
param location string
//param _artifactsLocation string
//param dscArchiveFile string
param adminUsername string
@secure()
param adminPassword string
param externalDnsHostName string
param deploymentPrefix string
@secure()
param selfSignedSSLCertificatePassword string
@secure()
param stroageKey string

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
        url: 'https://lukearcgisstorageusdemo.blob.core.windows.net/arcgis-stageartifacts/DSC.zip?sp=r&st=2023-06-16T13:49:31Z&se=2023-06-30T21:49:31Z&spr=https&sv=2022-11-02&sr=b&sig=be44yWeGnYBP3kXWHzjBKLwe6rtFZIIffKyDYlXvYP4%3D' //'${_artifactsLocation}/${dscArchiveFile}'
        function: 'ServerConfiguration'
        script: 'ServerConfiguration.ps1'
      }
      configurationArguments: {
        ServiceCredentialIsDomainAccount: adminUsername
        //https://github.com/Esri/arcgis-powershell-dsc/releases/download/v4.1.0/arcgis-powershell-dsc.zip
        PublicKeySSLCertificateFileUrl: 'https://lukearcgisstorageusdemo.blob.core.windows.net/arcgis-stageartifacts/trusted-wildcard-lukesprojects.com.pfx?sp=r&st=2023-06-16T13:50:38Z&se=2023-06-30T21:50:38Z&spr=https&sv=2022-11-02&sr=b&sig=uIfzObZqRKTNiL8aXZEJhpzc5KgijvNhMDYPE90vwvQ%3D'
        ServerLicenseFileUrl: 'https://lukearcgisstorageusdemo.blob.core.windows.net/arcgis-stageartifacts/ArcGISGISServerAdvanced_ArcGISServer_1306289.prvc?sp=r&st=2023-06-16T13:51:13Z&se=2023-06-30T21:51:13Z&spr=https&sv=2022-11-02&sr=b&sig=J9seKL6k6oLBHsqbRO63iLbj4HvREH0W82LMnZYESH8%3D'
        ServerMachineNames: vmName
        FileShareName: 'esri'
        ExternalDNSHostName: externalDnsHostName
        UseCloudStorage: true
        UseAzureFiles: true
        EnableLogHarvesterPlugin: false
        ServerContext: 'server'
      }
      protectedSettings: {
        ServerInternalCertificatePassword: {
          userName: 'Placeholder'
          password: selfSignedSSLCertificatePassword
        }
        StorageAccountCredential: {
          userName: substring('${deploymentPrefix}${replace(guid(subscription().id, resourceGroup().name, location), '-', '')}', 0, 23)
          password: stroageKey 
        }
        SiteAdministratorCredential: {
          userName: adminUsername
          password: adminPassword
        }
        ServiceCredential: {
          userName: adminUsername
          password: adminPassword
        }
      }
    } 
  }
}
