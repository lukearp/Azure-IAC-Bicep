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
    $scaleset = Get-AzVMss -ResourceGroupName $resourceGroup -VMScaleSetName $scalesetName
    $scaleset.Sku.Capacity = 0
    Update-AzVmss -VirtualMachineScaleSet $scaleset -ResourceGroupName $resourceGroup -VMScaleSetName $scalesetName
    return $computerNames
}
Connect-AzAccount -Identity -Subscription $subscription
$DeploymentScriptOutputs = @{};
$DeploymentScriptOutputs['computerNames']= Remove-Scaleset -scaleset $scalesetName -resourceGroup $resourceGroup