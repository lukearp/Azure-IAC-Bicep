param subscriptionName string
param vnetAddressSpaces array
@metadata({
  description: 'see readme for Subnet Object reference'
})
param subnets array
param userManagedIdentityId string

module deploymentScript '../../Modules/Microsoft.Resources/deploymentScripts/deploymentScripts-powershell.bicep' = {
  name: 'IPCarveTest'
  params: {
    arguments: '-subscription \\"${subscriptionName}\\" -subnets \\"${replace(string(subnets),'"','`\\"')}\\" -vnetAddressSpaces \\"${replace(string(vnetAddressSpaces),'"','`\\"')}\\"'
    location: 'eastus'
    managedIdentityId: userManagedIdentityId
    name: '${subscriptionName}-${split(userManagedIdentityId,'/')[8]}'
    pscriptUri: 'https://raw.githubusercontent.com/lukearp/Azure-IAC-Bicep/master/Scripts/VNET-IP-Segmentation/VNET-AddressSpace-Carve-DeploymentScript.ps1'   
    azPowershellVersion: '5.9' 
    supportingScriptUris: []      
  } 
}

output carvedSubnets array = deploymentScript.outputs.results['subnetObjs']
