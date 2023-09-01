param (
    [Parameter(Mandatory=$true)]
    [string]$resourceGroupName,
    [switch]$Disable
)

$logicApps = Get-AzLogicApp -ResourceGroupName $resourceGroupName
foreach($logicApp in $logicApps)
{
    if($Disable)
    {
        Set-AzLogicApp -Name $logicApp.Name -ResourceGroupName $logicApp.Id.split("/")[4] -State Disabled -Force -Confirm:$false
    }
    else
    {
        Set-AzLogicApp -Name $logicApp.Name -ResourceGroupName $logicApp.Id.split("/")[4] -State Enabled -Force -Confirm:$false
    }
}