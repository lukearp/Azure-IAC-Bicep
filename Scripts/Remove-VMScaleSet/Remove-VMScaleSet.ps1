param(
    [string] $scalesetName,
    [string] $resourceGroup,
    [string] $subscription
)
function Remove-Scaleset {
    param(
        [string] $scalesetName,
        [string] $resourceGroup
    )
    $instances = Get-AzVmssVM -ResourceGroupName $resourceGroup -VMScaleSetName $scalesetName;    
    $vmss = Remove-AzVmss -ResourceGroupName $resourceGroup -VMScaleSetName $scalesetName -Force -Confirm:$false;
    $computerNames = @();
    foreach($instance in $instances)
    {
        $computerNames += $instance.OsProfile.ComputerName;
    }
    return $computerNames;
}
Connect-AzAccount -Identity -Subscription $subscription;
$DeploymentScriptOutputs = @{};
$DeploymentScriptOutputs['computerNames']= Remove-Scaleset -scaleset $scalesetName -resourceGroup $resourceGroup;