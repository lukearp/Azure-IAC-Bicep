param hubVnet string
param spokeVnet string
param userAssignedIdentity string
param location string

var spokeName = split(spokeVnet,'/')[8]

resource removeHub 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  kind: 'AzurePowerShell'
  name: 'Remove-Hub'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentity}': {}
    }  
  }
  properties: {
    arguments: '${hubVnet}/virtualNetworkPeerings/To-${spokeName}'
    scriptContent: 'Connect-AzAccount -Identity -SubscriptionId $args[0].Split("/")[2];$peerRemove = Remove-AzVirtualNetworkPeering -VirtualNetworkName $args[0].Split("/")[8] -ResourceGroupName $args[0].Split("/")[4] -Name $args[0].Split("/")[10] -Force -Confirm:$false;$DeploymentScriptOutputs = @{};$DeploymentScriptOutputs[\'output\'] = $peerRemove;' 
    azPowerShellVersion: '5.9'
    retentionInterval: 'PT1H' 
  }  
}

resource removeSpoke 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  kind: 'AzurePowerShell'
  name: 'Remove-Spoke'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentity}': {}
    }  
  }
  properties: {
    arguments: '${spokeVnet}/virtualNetworkPeerings/To-HUB'
    scriptContent: 'Connect-AzAccount -Identity -SubscriptionId $args[0].Split("/")[2];$peerRemove = Remove-AzVirtualNetworkPeering -VirtualNetworkName $args[0].Split("/")[8] -ResourceGroupName $args[0].Split("/")[4] -Name $args[0].Split("/")[10] -Force -Confirm:$false;$DeploymentScriptOutputs = @{};$DeploymentScriptOutputs[\'output\'] = $peerRemove;'
    azPowerShellVersion: '5.9'
    retentionInterval: 'PT1H' 
  }  
}
