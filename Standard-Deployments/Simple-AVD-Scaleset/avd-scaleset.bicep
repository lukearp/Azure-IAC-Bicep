param scaleSetName string
param vmPrefix string
param location string
param hostpoolResourceId string
param managedIdentityId string

module removeHostsFromScaleSet '../../Modules/Microsoft.Resources/deploymentScripts/deploymentScripts-powershell.bicep' = {
  name: 'Remove-VMs-From-${scaleSetName}'
  params: {
    arguments: ''
    managedIdentityId: managedIdentityId  
    name: 'Remove-VMs-${scaleSetName}' 
    pscriptUri: 'https://raw.githubusercontent.com/lukearp/Azure-IAC-Bicep/master/Scripts/Remove-VMScaleSetInstances/Remove-VMScaleSetInstances.ps1'
    location: location 
  }
}
module removeHostsFromPool '../../Modules/Microsoft.Resources/deploymentScripts/deploymentScripts-powershell.bicep' = {
  name: 'Remove-VMs-${split(hostpoolResourceId,'/')[8]}-${scaleSetName}' 
  scope: resourceGroup(split(hostpoolResourceId,'/')[4]) 
  params: {
    arguments: ''
    managedIdentityId: managedIdentityId  
    name: 'Remove-Hosts-${scaleSetName}' 
    pscriptUri: 'https://raw.githubusercontent.com/lukearp/Azure-IAC-Bicep/master/Scripts/Remove-VMsFromAVDHostPool/Remove-VMsFromAVDHostPool.ps1'
    location: location   
  } 
}
