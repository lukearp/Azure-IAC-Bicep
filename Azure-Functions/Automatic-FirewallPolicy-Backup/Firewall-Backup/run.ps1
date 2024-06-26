param($eventGridEvent, $TriggerMetadata)

$ContainerName = $env:ContainerName #"Storage Container Name"
$StorageAccountName = $env:StorageAccountName #"Storage Account Name"
$StorageAccountResourceGroupName = $env:StorageAccountResourceGroupName #Resource Group of Storage Account"
$StorageAccountSubscription = $env:StorageAccountSubscription #"Subscription of storage account"
$testing = $env:Testing #$true for True $false for False
$testFirewallPolicyId = $env:TestFirewallPolicy # Resource ID of test firewall policy

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
$firewallPolicyTemplate = ConvertFrom-Json -InputObject $content

Write-Output $content
$ipGroups = @()
$ipGroups += ($firewallPolicyTemplate.parameters | Get-Member | ?{$_.MemberType -eq "NoteProperty" -and $_.Name -like "ipGroups_*_externalid*"})
$firewallPolicyTemplate.parameters = New-Object -TypeName psobject
$firewallPolicyTemplate.parameters | Add-Member -MemberType NoteProperty -Name "firewallPolicies_$($policyName.Replace("-","_"))_name" -Value $(New-Object -TypeName psobject -Property @{ defaultValue =  "$($policyName)-Backup"; type = "string"})
$firewallPolicyTemplate.variables | Add-Member -MemberType NoteProperty -name "User" -Value $user
$content = $firewallPolicyTemplate | ConvertTo-Json -Depth 100
$graphQuery = "resources | where type == `"microsoft.network/ipgroups`" | project id,name"
$ipGroupResourceIds = Search-AzGraph -Query $graphQuery -First 1000
foreach($ipGroup in $ipGroups)
{
    $resourceId = $null
    $ipGroupName = $ipGroup.Name.Split("ipGroups_")[1].Split("_externalid")[0]    
    $resourceId = ($ipGroupResourceIds | ?{$_.name -match $ipGroupName.Replace("_","[\-_\.]") -and $_.name.Length -eq $ipGroupName.Length}).id
    if($resourceId.count -gt 1)
    {
        $resourceId = $resourceId | ?{$_ -like "/subscriptions/$($subscription)/*"}
    }
    $content = $content.Replace("[parameters('$($ipGroup.Name)')]",$resourceId).Replace("parameters('$($ipGroup.Name)')",$resourceId)
}
$firewallPolicyTemplate = ConvertFrom-Json -InputObject $content

$count = 0
$dependsOn = @()
$stringDepends = "[resourceId('Microsoft.Network/firewallPolicies/ruleCollectionGroups',parameters('firewallPolicies_$($policyName.Replace("-","_"))_name'),'{0}')]"
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

Select-AzSubscription -Subscription $StorageAccountSubscription

$context = (Get-AzStorageAccount -Name $StorageAccountName -ResourceGroupName $StorageAccountResourceGroupName).Context

Set-AzStorageBlobContent -File $tempFile.FullName -Container $ContainerName -Blob "$($policyName).json" -Context $context -StandardBlobTier Hot -Force
