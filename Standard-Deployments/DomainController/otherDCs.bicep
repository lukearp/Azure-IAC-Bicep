param vmNamePrefix string
param location string
param count int
param zones array
param vmProperties array
param dscConfigScript string
param domainUserName string
param domainFqdn string
param domainSite string
@secure()
param domainPassword string
param managedIdentityId string
param psScriptLocation string

var vmNames = [for i in range(0, count): '${vmNamePrefix}-${string(i + 2)}']

resource otherDc 'Microsoft.Compute/virtualMachines@2020-12-01' = [for i in range(0, count): {
  location: location
  name: vmNames[i]
  zones: zones[i + 1]
  properties: vmProperties[i + 1]
}]

resource otherDcExtension 'Microsoft.Compute/virtualMachines/extensions@2020-12-01' = [for i in range(0, count): {
  name: '${vmNames[i]}/DC-Creation'
  location: location
  dependsOn: [
    otherDc
  ]
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.73'
    autoUpgradeMinorVersion: true
    settings: {
      modulesUrl: dscConfigScript
      configurationFunction: 'DomainControllerConfig.ps1\\DomainControllerConfig'
      properties: [
        {
          Name: 'creds'
          Value: {
            UserName: domainUserName
            Password: 'PrivateSettingsRef:domainPassword'
          }
          TypeName: 'System.Management.Automation.PSCredential'
        }
        {
          Name: 'domain'
          Value: domainFqdn
          TypeName: 'System.String'
        }
        {
          Name: 'site'
          Value: domainSite
          TypeName: 'System.String'
        }
        {
          Name: 'newForest'
          Value: false
          TypeName: 'System.Boolean'
        }
      ]
    }
    protectedSettings: {
      Items: {
        domainPassword: domainPassword
      }
    } 
  }
}]

resource rebootOtherVms 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  kind: 'AzurePowerShell'
  location: location
  name: 'Reboot-OtherDCs'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityId}':{}
    }  
  } 
  properties: {
    arguments: '${array(vmNames)} ${resourceGroup().name} ${subscription().subscriptionId}'
    primaryScriptUri: psScriptLocation 
    azPowerShellVersion: '5.9'
    retentionInterval: 'PT1H'    
  } 
  dependsOn: [
    otherDcExtension     
  ]    
}
