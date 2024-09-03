$subscriptionId = ""
$extensionName = "" #Example: MDE.Windows

$query = @'
resources
| where type == "microsoft.hybridcompute/machines"
| where subscriptionId == "{0}"
| project name, resourceGroup
'@
$servers = Search-AzGraph -Query $($query -f $subscriptionId)
Select-AzSubscription -Subscription $subscriptionId

foreach($server in $servers)
{
    $arcVMExtension = Get-AzConnectedMachineExtension -MachineName $server.name -ResourceGroupName $server.resourceGroup -SubscriptionId $subscriptionId -Name $extensionName
    if($null -ne $arcVMExtension)
    {
        # Remove the extension
        Remove-AzConnectedMachineExtension -ResourceGroupName $server.resourceGroup -MachineName $server.name -Name $extensionName
    }
}