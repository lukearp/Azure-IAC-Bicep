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
    $instances = Get-AzVmssVM -ResourceGroupName $resourceGroup -VMScaleSetName $scalesetName
    $computerNames = @()
    foreach($instance in $instances)
    {
        $computerNames += $instance.OsProfile.ComputerName
    }
    Remove-AzVmss -ResourceGroupName $resourceGroup -VMScaleSetName $scalesetName -Force -Confirm:$false
    return $computerNames
}
Connect-AzAccount -Identity -Subscription $subscription
$DeploymentScriptOutputs = @{};
$DeploymentScriptOutputs['computerNames']= Remove-Scaleset -scaleset $scalesetName -resourceGroup $resourceGroup