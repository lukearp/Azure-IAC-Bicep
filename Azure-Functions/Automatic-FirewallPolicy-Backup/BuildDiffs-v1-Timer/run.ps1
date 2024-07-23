# Input bindings are passed in via param block.
param($Timer)

$ContainerName = $env:ContainerName #"Storage Container Name"
$TargetContainer = $env:TargetContainer
$StorageAccountName = $env:StorageAccountName #"Storage Account Name"
$StorageAccountResourceGroupName = $env:StorageAccountResourceGroupName #Resource Group of Storage Account"
$StorageAccountSubscription = $env:StorageAccountSubscription #"Subscription of storage account"
$LogicAppEndpoint = $env:LogicAppEndpoint

$lastHour = [datetime]::UtcNow.AddHours(-1);
Select-AzSubscription -Subscription $StorageAccountSubscription
$storageAccount = Get-AzStorageAccount -Name $StorageAccountName -ResourceGroupName $StorageAccountResourceGroupName
$firewallPolicies = Get-AzStorageBlob -Container $ContainerName -Context $storageAccount.Context
$modifiedPolicies = $firewallPolicies | ? { $_.LastModified -gt $lastHour }
foreach ($policy in $modifiedPolicies) {
    $policyName = $policy.Name.Split(".json")[0]
    $tempFile = New-TemporaryFile
    $versions = Get-AzStorageBlob -IncludeVersion -Container $ContainerName -Prefix $($policyName + ".json") -Context $storageAccount.Context
    $newBlob = (Get-AzStorageBlob -Container $ContainerName -Blob $($policyName + ".json") -Context $storageAccount.Context).ICloudBlob.DownloadText()
    $oldBlobVersion = ($versions | ?{$_.LastModified -lt $lastHour})[-1].VersionId
    Get-AzStorageBlob -Container $ContainerName -Blob $($policyName + ".json") -VersionId $oldBlobVersion -Context $storageAccount.Context | Get-AzStorageBlobContent -Path $tempFile.FullName -Force 
    $oldBlob = (Get-Content -Path $tempFile.FullName)
    $oldBlob = ($oldBlob -join "") | ConvertFrom-Json -Depth 100 | ConvertTo-Json -Depth 100
    # Write to the Azure Functions log stream.
    Import-Module "$($PSScriptRoot)\bin\DiffPlex.dll"
    $differ = New-Object DiffPlex.Differ
    $sideBySideBuilder = New-Object DiffPlex.DiffBuilder.SideBySideDiffBuilder($differ)

    $oldReportTmp = New-TemporaryFile
    $newReportTmp = New-TemporaryFile
    $report = $sideBySideBuilder.BuildDiffModel($newBlob, $oldBlob)
    $report.OldText.Lines | Select Type, Text | Out-File -FilePath $oldReportTmp.FullName -Force
    $report.NewText.Lines | Select Type, Text | Out-File -FilePath $newReportTmp.FullName -Force

    Set-AzStorageBlobContent -File $oldReportTmp.FullName -Container $TargetContainer -Blob $($policyName + "-DifVersion-" + $versions[-1].VersionId.Replace(":", "_") + "-" + $versions[$versions.count - 2].VersionId.Replace(":", "_") + "-OLDTEXT.txt") -Context $storageAccount.Context -Force
    Set-AzStorageBlobContent -File $newReportTmp.FullName -Container $TargetContainer -Blob $($policyName + "-DifVersion-" + $versions[-1].VersionId.Replace(":", "_") + "-" + $versions[$versions.count - 2].VersionId.Replace(":", "_") + "-NEWTEXT.txt") -Context $storageAccount.Context -Force
    $storageUrl = "https://portal.azure.com/#view/Microsoft_Azure_Storage/BlobPropertiesBladeV2/storageAccountId/%2Fsubscriptions%2F{0}%2FresourceGroups%2F{1}%2Fproviders%2FMicrosoft.Storage%2FstorageAccounts%2F{2}/path/{3}%2F{4}/isDeleted~/false/tabToload~/0"
    $blobBody = @'
{{
    "policyName": {0},
    "old": "{1}",
    "new": "{2}"
}}
'@
    $storageUrl = "https://portal.azure.com/#view/Microsoft_Azure_Storage/BlobPropertiesBladeV2/storageAccountId/%2Fsubscriptions%2F{0}%2FresourceGroups%2F{1}%2Fproviders%2FMicrosoft.Storage%2FstorageAccounts%2F{2}/path/{3}%2F{4}/isDeleted~/false/tabToload~/0"
    $oldUri = $storageUrl -f $StorageAccountSubscription, $StorageAccountResourceGroupName, $StorageAccountName, $TargetContainer, $($policyName + "-DifVersion-" + $versions[-1].VersionId.Replace(":", "_") + "-" + $versions[$versions.count - 2].VersionId.Replace(":", "_") + "-OLDTEXT.txt")
    $newUri = $storageUrl -f $StorageAccountSubscription, $StorageAccountResourceGroupName, $StorageAccountName, $TargetContainer, $($policyName + "-DifVersion-" + $versions[-1].VersionId.Replace(":", "_") + "-" + $versions[$versions.count - 2].VersionId.Replace(":", "_") + "-NEWTEXT.txt")

    $jBody = $blobBody -f $policyName, $oldUri, $newUri
    $triggerEmail = Invoke-RestMethod -Method Post -ContentType "application/json" -Body $jBody -Uri $LogicAppEndpoint
}
