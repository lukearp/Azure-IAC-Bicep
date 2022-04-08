param (
    $tenantId
)

$subscriptions = Get-AzSubscription -TenantId $tenantId
$nsgInRules = @()
$nsgOutRules = @()
$vnetSubnetsWithoutNSGS = @()
$report = @()
foreach($sub in $subscriptions)
{
    Select-AzSubscription -SubscriptionObject $sub
    $vnets = Get-AzVirtualNetwork
    $networkSecurityGroups = Get-AzNetworkSecurityGroup
    foreach($nsg in $networkSecurityGroups)
    {
        if($nsg.SecurityRules.Count -gt 0 -and ($nsg.NetworkInterfaces.Count -gt 0 -or $nsg.Subnets.Count -gt 0))
        {
            $nsgInRules += New-Object -TypeName psobject -Property @{
                nsgResourceGroup = $nsg.Id.Split("/")[4]
                nsgName = $nsg.Name
                rules = $nsg.SecurityRules | ?{$_.Direction -eq "Inbound"}
                subnets = $nsg.Subnets.Count -gt 0 ? $nsg.Subnets.Id.Split("/")[-1] : @()
                interfaces = $nsg.NetworkInterfaces.Count -gt 0 ? $nsg.NetworkInterfaces.Id.Split("/")[-1] : @()
            }
        }
    }
    foreach($vnet in $vnets)
    {
        $subnetNoNsg = $vnet.Subnets | ?{$_.NetworkSecurityGroup.Id -eq $null}
        if($subnetNoNsg.Count -gt 0)
        {
            $vnetSubnetsWithoutNSGS += New-Object -TypeName psobject -Property @{
                vnet = $vnet.Name
                vnetResourceGroup = $vnet.Id.Split("/")[4]
                subnetNoNsg = $subnetNoNsg.Name
            }
        }
    }
    $report += New-Object -TypeName psobject -Property @{
        SubscriptionName=$sub.Name
        SubscriptionId = $sub.Id
        NSGsWithSecurityRules = $nsgInRules
        VNetsWithNoNSG = $vnetSubnetsWithoutNSGS
    }
}

ConvertTo-Json -InputObject $report > "$($PWD.Path)\report.json"