param (
    [string]$firewallPolicyId,
    [string]$fileName = "backup.json"
)

$resourceGroup = $firewallPolicyId.Split("/")[4]
$policyName = $firewallPolicyId.Split("/")[8]
Export-AzResourceGroup -ResourceGroupName $resourceGroup -Resource $firewallPolicyId -Path "$($PSScriptRoot)\$($fileName)" #$eventGridEvent.data.resourceUri
$firewallPolicyTemplate = ConvertFrom-Json -InputObject $((Get-Content -Path "$($PSScriptRoot)\$($fileName)") -join "")
$firewallPolicyTemplate.parameters.firewallPolicies_Parent_Policy_name | Add-Member -MemberType Noteproperty -Name "defaultValue" -Value $policyName
$ipGroups = @()
$ipGroups += ($firewallPolicyTemplate.parameters | Get-Member | ?{$_.MemberType -eq "NoteProperty" -and $_.Name -like "ipGroups_*_externalid"}).Name.Split("ipGroups_")[1].Split("_externalid")[0]
foreach($ipGroup in $ipGroups)
{
    $resourceId = $null
    
    $resourceId = Get-AzResource -Name $ipGroup -ResourceType "Microsoft.Network/ipGroups" #Get-AzIpGroup -Name $ipGroup -ResourceGroupName $resourceGroup -ErrorAction SilentlyContinue
    if($null -eq $resourceId)
    {
        $resourceId = Get-AzResource -Name $ipGroup.Replace("_","-") -ResourceType "Microsoft.Network/ipGroups" #Get-AzIpGroup -name $ipGroup.Replace("_","-") -ResourceGroupName $resourceGroup
    } 
    $firewallPolicyTemplate.parameters."ipGroups_$($ipGroup)_externalid" | Add-Member -MemberType NoteProperty -Name "defaultValue" -Value $resourceId.Id 
}
$count = 0
$groups = @()
$dependsOn = @()
$stringDepends = "[resourceId('Microsoft.Network/firewallPolicies/ruleCollectionGroups',parameters('firewallPolicies_Parent_Policy_name'),'{0}')]"
foreach($ruleGroup in $firewallPolicyTemplate.resources | ?{$_.type -eq "Microsoft.Network/firewallPolicies/ruleCollectionGroups"})
{    
    if($count -gt 0)
    {
        $ruleGroup.dependsOn += $dependsOn
    }
    $dependsOn += "$($stringDepends -f $ruleGroup.name.split("/")[1].split("'")[0])"
    $count++
}

ConvertTo-Json -InputObject $firewallPolicyTemplate -Depth 100 | Out-File "$($PSScriptRoot)\$($fileName)"