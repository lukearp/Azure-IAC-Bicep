$appGatewayName = "test"
$appGatewayResourceGroupName = "temp-appgw"

$appGateway = Get-AzApplicationGateway -Name $appGatewayName -ResourceGroupName $appGatewayResourceGroupName
$associatedPolicies = @($appGateway.FirewallPolicy.Id)
$associatedPolicies += @($appGateway.HttpListeners.FirewallPolicy.Id)
$wafPolicies = Get-AzApplicationGatewayFirewallPolicy
$wafPoliciesByExclusion = @()
$exclusionCount = 0
foreach($policy in $wafPolicies)
{
    $wafPoliciesByExclusion += New-Object -TypeName psobject -Property @{
        id = $policy.Id
        count = $policy.ManagedRules.Exclusions.Count
    }
}
foreach($associatedPolicy in $associatedPolicies)
{
    $exclusionCount += ($wafPoliciesByExclusion | ?{$_.id -eq $associatedPolicy}).count
}
$exclusionCount