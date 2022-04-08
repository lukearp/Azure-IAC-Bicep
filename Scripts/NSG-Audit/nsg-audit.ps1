param (
    $tenantId
)

$subscriptions = Get-AzSubscription -TenantId $tenantId
$nsgInRules = @()
$connectedDevices = @()
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
                interfaces = $nsg.NetworkInterfaces.Count -gt 0 ? $nsg.NetworkInterfaces.Id : @()
            }
        }
    }
    foreach($vnet in $vnets)
    {
        $subnetNoNsg = $vnet.Subnets | ?{$_.NetworkSecurityGroup.Id -eq $null}
        foreach($subnet in $vnet.Subnets)
        {            
            if($subnet.NetworkSecurityGroup.Id -eq $null)
            {
                $vnetSubnetsWithoutNSGS += New-Object -TypeName psobject -Property @{
                    vnet = $vnet.Name
                    vnetResourceGroup = $vnet.Id.Split("/")[4]
                    subnetNoNsg = $subnetNoNsg.Name
                }
            }
            $connectedDevices += New-Object -TypeName psobject -Property @{
                subnetName = $subnet.Name
                interfaces = $subnet.IpConfigurations.Id
            }
        }
    }
    $report += New-Object -TypeName psobject -Property @{
        SubscriptionName=$sub.Name
        SubscriptionId = $sub.Id
        NSGsWithSecurityRules = $nsgInRules
        VNetsWithNoNSG = $vnetSubnetsWithoutNSGS
        ConnectedDevices = $connectedDevices
    }
}

ConvertTo-Json -InputObject $report -Depth 10 > "$($PWD.Path)\report.json"