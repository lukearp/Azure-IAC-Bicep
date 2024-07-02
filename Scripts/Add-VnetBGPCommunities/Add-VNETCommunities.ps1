Import-Module -Name Az.ResourceGraph

$query = @"
resources
| where type =~ "microsoft.network/virtualNetworks"
"@

$regionCommunityTable = @{
    eastus = "12076:20001"
    westus = "12076:20002"
    northcentralus = "12076:20003"
    centralus = "12076:20004"
}

$vnets = Search-AzGraph -Query $query

foreach($vnet in $vnets)
{
    Select-AzSubscription $vnet.subscriptionId
    $thisVnet = Get-AzVirtualNetwork -Name $vnet.name -ResourceGroupName $vnet.resourceGroup
    $thisVnet.BgpCommunities = New-Object -TypeName Microsoft.Azure.Commands.Network.Models.PSVirtualNetworkBgpCommunities -Property @{
        virtualNetworkCommunity = $regionCommunityTable[$vnet.location]
    }
    Set-AzVirtualNetwork -VirtualNetwork $thisVnet
}
