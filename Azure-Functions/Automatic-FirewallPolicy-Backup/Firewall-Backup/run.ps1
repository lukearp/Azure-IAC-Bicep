param($eventGridEvent, $TriggerMetadata)

# Set Vars
$ContainerName = ""
$StorageAccountName = ""
$StorageAccountResourceGroupName = "" 
$testing = $true
$testFirewallPolicyId = ""

# Make sure to pass hashtables to Out-String so they're logged correctly
$firewallPolicyId = ""
if($testing -eq $false) {
    $user = $eventGridEvent.data.claims['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/upn']
    $firewallPolicyId = $eventGridEvent.data.resourceUri.split("/")[0..8] -join "/"
} else {
    $user = "testuser@test.com"
    $firewallPolicyId = $testFirewallPolicyId
}
$subscription = $firewallPolicyId.Split("/")[2]
$resourceGroup = $firewallPolicyId.Split("/")[4]
$policyName = $firewallPolicyId.Split("/")[8]

$tempFile = New-TemporaryFile
#$fileName = "$($policyName)_$((Get-Date -f s).Replace(":","-")).json"
Select-AzSubscription -Subscription $subscription
Export-AzResourceGroup -ResourceGroupName $resourceGroup -Resource $firewallPolicyId -Path $tempFile.FullName #$eventGridEvent.data.resourceUri
$content = (Get-Content -Path "$($tempFile.FullName).json") -join ""
Write-Output $content
$firewallPolicyTemplate = ConvertFrom-Json -InputObject $content
$firewallPolicyTemplate.parameters | Get-Member | ?{$_.Name -like "firewallPolicies_*_name"} | Add-Member -MemberType Noteproperty -Name "defaultValue" -Value $policyName
$firewallPolicyTemplate.variables | Add-Member -MemberType NoteProperty -name "User" -Value $user
$ipGroups = @()
$ipGroups += ($firewallPolicyTemplate.parameters | Get-Member | ?{$_.MemberType -eq "NoteProperty" -and $_.Name -like "ipGroups_*_externalid"})
foreach($ipGroup in $ipGroups)
{
    $resourceId = $null
    $ipGroupName = $ipGroup.Name.Split("ipGroups_")[1].Split("_externalid")[0]
    $resourceId = Get-AzIpGroup -Name $ipGroupName -ResourceGroupName $resourceGroup -ErrorAction SilentlyContinue
    if($null -eq $resourceId)
    {
        $resourceId = Get-AzIpGroup -name $ipGroupName.Replace("_","-") -ResourceGroupName $resourceGroup
    } 
    $firewallPolicyTemplate.parameters."ipGroups_$($ipGroupName)_externalid" | Add-Member -MemberType NoteProperty -Name "defaultValue" -Value $resourceId.id
}
$count = 0
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

$(ConvertTo-Json -InputObject $firewallPolicyTemplate -Depth 100) | Out-File -FilePath $tempFile.FullName

$context = (Get-AzStorageAccount -Name $StorageAccountName -ResourceGroupName $StorageAccountResourceGroupName).Context

Set-AzStorageBlobContent -File $tempFile.FullName -Container $ContainerName -Blob "$($policyName).json" -Context $context -StandardBlobTier Hot -Force