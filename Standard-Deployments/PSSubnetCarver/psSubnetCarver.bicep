param subscriptionName string
param vnetAddressSpaces array
@metadata({
  description: 'see readme for Subnet Object reference'
})
param subnets array
param userManagedIdentityId string

module deploymentScript '../../Modules/Microsoft.Resources/deploymentScripts/deploymentScripts-powershell.bicep' = {
  name: '${subscriptionName}-IPCarveTest'
  params: {
    arguments: '-subscription \\"${subscriptionName}\\" -subnets \\"${replace(string(subnets),'"','`\\"')}\\" -vnetAddressSpaces \\"${replace(string(vnetAddressSpaces),'"','`\\"')}\\"'
    location: 'eastus'
    managedIdentityId: userManagedIdentityId
    name: '${subscriptionName}-${split(userManagedIdentityId,'/')[8]}'
    pscriptUri: 'https://raw.githubusercontent.com/lukearp/Azure-IAC-Bicep/cfec975fe9816dc5ae464d162fb315afa2b9ebc8/Scripts/VNET-IP-Segmentation/VNET-AddressSpace-Carve-DeploymentScript.ps1'   
    azPowershellVersion: '6.6' 
    supportingScriptUris: []      
  } 
}

output carvedSubnets array = deploymentScript.outputs.results['subnetObjs']
