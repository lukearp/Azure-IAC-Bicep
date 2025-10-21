param (
    [string]$localPath = ".",
    [int]$maxIpGroups = 1000
)

$tenantId = "92247f12-056e-4600-9248-fb43a78491c9"
$ipGroups = Search-AzGraph -Query "resources | where type =~ `"Microsoft.Network/ipGroups`"" -First $maxIpGroups -ManagementGroup $tenantId
$resourceIds = $ipGroups.ResourceId
$subscriptions = @()
foreach ($resourceId in $resourceIds) {
    $subscriptions += $resourceId.Split("/")[2]
}
$ipGroupFull = @()
foreach ($sub in $($subscriptions | Select -Unique)) {
    Select-AzSubscription -Subscription $sub
    foreach ($group in $($ipGroups | ?{$_.ResourceId -like "*/$($sub)/*"})) {
        $fullGroup = $null
        $fullGroup = Get-AzIpGroup -Name $group.Name -ResourceGroupName $group.ResourceGroup
        $ipGroupFull += New-Object -TypeName psobject -Property @{
            name        = $fullGroup.Name
            resourceId  = $group.ResourceId
            ipAddresses = $fullGroup.IpAddresses  
        }
    }
}

$firewallPolicies = Search-AzGraph -Query "resources | where type =~ `"Microsoft.Network/firewallPolicies`"" -First $maxIpGroups -ManagementGroup $tenantId
$resourceIds = $firewallPolicies.ResourceId
$subscriptions = @()
foreach ($resourceId in $resourceIds) {
    $subscriptions += $resourceId.Split("/")[2]
}
$csvSuffix = (Get-Date -f s).Replace(":", "-")
$count = 0

foreach ($sub in $($subscriptions | Select -Unique)) {
    Select-AzSubscription -Subscription $sub
    foreach ($policy in $firewallPolicies) {
        $csvPath = "$($localPath)\$($policy.Name)_$($csvSuffix)_$($count).csv"
        Add-Content -Path $csvPath -Value "RuleCollection,CollectionPriority,CollectionGroup,GroupPriority,RuleName,SourceIPGroup,SourceIPs,DestinationIPGroup,DestinationIPs,DestinationPort,Action,RuleType"
        $fullPolicy = Get-AzFirewallPolicy -Name $policy.Name -ResourceGroupName $policy.ResourceGroup
        foreach ($ruleGroup in $fullPolicy.RuleCollectionGroups) {
            $fullRuleGroup = Get-AzFirewallPolicyRuleCollectionGroup -Name $ruleGroup.Id.Split("/")[10] -ResourceGroupName $ruleGroup.Id.Split("/")[4] -AzureFirewallPolicyName $policy.Name
            foreach ($collection in $fullRuleGroup.Properties.RuleCollection | Sort-object Priority) {
                foreach ($rule in $collection.Rules) {
                    $sourceAddressPrefixes = @()
                    $destAddressPrefixes = @()
                    $source = @()
                    foreach ($sourceIpGroup in $rule.SourceIpGroups) {
                        $source += $sourceIpGroup.split("/")[8]
                    }
                    $destination = @()
                    foreach ($destinationIpGroup in $rule.DestinationIPGroups) {
                        $destination += $destinationIpGroup.split("/")[8]
                    }
                    if ($rule.SourceIpGroups.Count -gt 0) {                                    
                        foreach ($group in $rule.SourceIpGroups) {
                            $sourceAddressPrefixes += ($ipGroupFull | ? { $_.name -eq $group.split("/")[8] }).ipAddresses
                        }
                    }
                    else {
                        $sourceAddressPrefixes = $rule.SourceAddresses
                    }
                    if ($rule.DestinationIpGroups.Count -gt 0) {  
                                          
                        foreach ($group in $rule.DestinationIpGroups) {
                            $destAddressPrefixes += ($ipGroupFull | ? { $_.name -eq $group.split("/")[8] }).ipAddresses
                        }
                    }
                    else {
                        if($rule.RuleType -ne "ApplicationRule")
                        {
                            $destAddressPrefixes = $rule.DestinationAddresses
                        }
                        else {
                            $json = $(New-Object -TypeName psobject -Property @{
                                TargetFqdns = $rule.TargetFqdns
                                Protocols = $rule.Protocols 
                            } | ConvertTo-Json -depth 10 -Compress)
                            $destAddressPrefixes = "$($json.replace('"','""'))"
                        }
                    }
                    if($rule.RuleType -eq "ApplicationRule") {
                        Add-Content -Path $csvPath -Value "$($collection.Name),$($collection.Priority),$($ruleGroup.Id.split("/")[10]),$($fullRuleGroup.Properties.Priority),$($rule.name.Replace(",","_")),$($source -join ";"),$($sourceAddressPrefixes -join ";"),$($destination -join ";"),"$($destAddressPrefixes)",$($rule.DestinationPorts -join ";"),$($collection.Action.Type),$($rule.RuleType)"
                    }
                    else {
                        Add-Content -Path $csvPath -Value "$($collection.Name),$($collection.Priority),$($ruleGroup.Id.split("/")[10]),$($fullRuleGroup.Properties.Priority),$($rule.name.Replace(",","_")),$($source -join ";"),$($sourceAddressPrefixes -join ";"),$($destination -join ";"),$($destAddressPrefixes -join ";"),$($rule.DestinationPorts -join ";"),$($collection.Action.Type),$($rule.RuleType)"
                    }
                }
            }
        }
        $count++
    }
}
