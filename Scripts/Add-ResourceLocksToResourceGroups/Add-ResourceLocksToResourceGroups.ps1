$subscriptions = Get-AzSubscription
foreach($sub in $subscriptions)
{
    Select-AzSubscription -SubscriptionObject $sub
    $resourceGroups = Get-AzResourceGroup
    foreach($rg in $resourceGroups)
    {
        $lock = $null
        $lock = Get-AzResourceLock -ResourceGroupName $rg.ResourceGroupName
        if($null -eq $lock)
        {
            New-AzResourceLock -ResourceGroupName $rg.ResourceGroupName -Name "Do-Not-Delete" -LockLevel CanNotDelete -Force
        }
    }
}