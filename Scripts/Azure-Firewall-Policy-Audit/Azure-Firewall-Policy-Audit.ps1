param (
    [string]$localPath
)

$ipGroups = Get-AzResource -ResourceType "Microsoft.Network/ipGroups" | ?{$_.ResourceId.Split("/") -contains (Get-AzContext).Subscription.Id}
$ipGroupFull = @()
foreach($group in $ipGroups)
{
    $fullGroup = $null
    $fullGroup = Get-AzIpGroup -Name $group.Name -ResourceGroupName $group.ResourceGroupName
    $ipGroupFull += New-Object -TypeName psobject -Property @{
        name = $fullGroup.Name
        resourceId = $group.ResourceId
        ipAddresses = $fullGroup.IpAddresses  
    }
}
$firewallPolicies = Get-AzResource -ResourceType "Microsoft.Network/firewallPolicies" | ?{$_.ResourceId.Split("/") -contains (Get-AzContext).Subscription.Id}
$csvSuffix = (Get-Date -f s).Replace(":","-")
$count = 0
foreach($policy in $firewallPolicies)
{
    $csvPath = "$($localPath)\$($policy.Name)_$($csvSuffix)_$($count).csv"
    Add-Content -Path $csvPath -Value "RuleCollection,CollectionPriority,CollectionGroup,GroupPriority,RuleName,SourceIPGroup,SourceIPs,DestinationIPGroup,DestinationIPs,DestinationPort,Action"
    $fullPolicy = Get-AzFirewallPolicy -Name $policy.Name -ResourceGroupName $policy.ResourceGroupName
    foreach($ruleGroup in $fullPolicy.RuleCollectionGroups)
    {
        $fullRuleGroup = Get-AzFirewallPolicyRuleCollectionGroup -Name $ruleGroup.Id.Split("/")[10] -ResourceGroupName $ruleGroup.Id.Split("/")[4] -AzureFirewallPolicyName $policy.Name
        foreach($collection in $fullRuleGroup.Properties.RuleCollection | Sort-object Priority)
        {
            foreach($rule in $collection.Rules)
            {
                $sourceAddressPrefixes = @()
                $destAddressPrefixes = @()
                $source = ""
                $destination = ""
                if($rule.SourceIpGroups.Count -gt 0) {   
                    $source = $rule.SourceIpGroups.split("/")[8] -join ";"                 
                    foreach($group in $rule.SourceIpGroups)
                    {
                        $sourceAddressPrefixes += ($ipGroupFull | ?{$_.name -eq $group.split("/")[8]}).ipAddresses
                    }
                } else {
                    $sourceAddressPrefixes = $rule.SourceAddresses
                }
                if($rule.DestinationIpGroups.Count -gt 0) {  
                    $destination = $rule.DestinationIpGroups.split("/")[8] -join ";"                  
                    foreach($group in $rule.DestinationIpGroups)
                    {
                        $destAddressPrefixes += ($ipGroupFull | ?{$_.name -eq $group.split("/")[8]}).ipAddresses
                    }
                } else {
                    $destAddressPrefixes = $rule.DestinationAddresses
                }
                Add-Content -Path $csvPath -Value "$($collection.Name),$($collection.Priority),$($ruleGroup.Id.split("/")[10]),$($fullRuleGroup.Properties.Priority),$($rule.name),$($source),$($sourceAddressPrefixes -join ";"),$($destination),$($destAddressPrefixes -join ";"),$($rule.DestinationPorts -join ";"),$($collection.Action.Type)"
            }
        }
    }
    $count++
}