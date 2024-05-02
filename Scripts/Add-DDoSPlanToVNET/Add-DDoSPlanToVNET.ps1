# Requires Az.ResourceGraph to be installed 

$query = 'resources | where type =~ "microsoft.network/virtualNetworks" | project name, resourceGroup, subscriptionId'
$vnets = Search-AzGraph -Query $query
$ddosPlanResourceId = ""

foreach($vnet in $vnets)
{
    Select-AzSubscription -Subscription $vnet.subscriptionId
    $thisVnet = Get-AzVirtualNetwork -Name $vnet.name -ResourceGroupName $vnet.resourceGroup
    $thisVnet.DdosProtectionPlan.Id = $ddosPlanResourceId
    Set-AzVirtualNetwork -VirtualNetwork $thisVnet
}