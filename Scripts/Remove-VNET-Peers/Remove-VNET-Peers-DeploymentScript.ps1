Connect-AzAccount -Identity -SubscriptionId $args[0].Split("/")[2];
$peerRemove = Remove-AzVirtualNetworkPeering -VirtualNetworkName $args[0].Split("/")[8] -ResourceGroupName $args[0].Split("/")[4] -Name $args[0].Split("/")[10] -Force -Confirm:$false
sleep 60
$DeploymentScriptOutputs = @{};
$DeploymentScriptOutputs['output'] = $peerRemove