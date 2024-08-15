$appGatewayName = "test"
$appGatewayResourceGroupName = "temp-appgw"

$appGateway = Get-AzApplicationGateway -Name $appGatewayName -ResourceGroupName $appGatewayResourceGroupName
$associatedPolicies = @($appGateway.FirewallPolicy.Id)
$associatedPolicies += @($appGateway.HttpListeners.FirewallPolicy.Id)
$wafPolicies = Get-AzApplicationGatewayFirewallPolicy
$wafPoliciesByExclusion = @()
foreach($policy in $wafPolicies)
{
    $countOfExcludedRules = $policy.ManagedRules.Exclusions.ExclusionManagedRuleSets.RuleGroups.Rules.RuleId
    if($null -ne $countOfExcludedRules)
    {
        $wafPoliciesByExclusion += New-Object -TypeName psobject -Property @{
            id = $policy.Id
            count = $policy.ManagedRules.Exclusions.Count
            excludedRules = $countOfExcludedRules | Group-Object | Select-Object Name, Count
        }
    }    
}
$exclusions = New-Object -TypeName psobject -Property @{
    totalExclusions = 0 
    excludedRules = @()
}
foreach($associatedPolicy in $associatedPolicies)
{    
    $exclusions.totalExclusions += ($wafPoliciesByExclusion | ?{$_.id -eq $associatedPolicy}).count
    if($null -ne ($wafPoliciesByExclusion | ?{$_.id -eq $associatedPolicy}).excludedRules)
    {
        $exclusions.excludedRules += ($wafPoliciesByExclusion | ?{$_.id -eq $associatedPolicy}).excludedRules
    }
    $exclusionReport += $exclusions
}
$exclusions | ConvertTo-Json -Depth 10