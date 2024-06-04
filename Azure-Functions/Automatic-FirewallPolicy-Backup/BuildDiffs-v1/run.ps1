using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

$ContainerName = $env:ContainerName #"Storage Container Name"
$StorageAccountName = $env:StorageAccountName #"Storage Account Name"
$StorageAccountResourceGroupName = $env:StorageAccountResourceGroupName #Resource Group of Storage Account"
$StorageAccountSubscription = $env:StorageAccountSubscription #"Subscription of storage account"
$testing = $env:Testing #$true for True $false for False
$testFirewallPolicyName = $env:testFirewallPolicyName # Resource ID of test firewall policy

$firewallPolicyId = ""
if($testing -eq $false) {
    $user = $Request.Body.user
    $policyName = $Request.Body.firewallPolicyName
} else {
    $user = "testuser@test.com"
    $policyName = $testFirewallPolicyName
}

Select-AzSubscription -Subscription $StorageAccountSubscription
$storageAccount = Get-AzStorageAccount -Name $StorageAccountName -ResourceGroupName $StorageAccountResourceGroupName
$tempFile = New-TemporaryFile
$versions = Get-AzStorageBlob -IncludeVersion -Container $ContainerName -Prefix $($policyName + ".json") -Context $storageAccount.Context
$newBlob = (Get-AzStorageBlob -Container $ContainerName -Blob $($policyName + ".json") -VersionId $versions[-1].VersionId -Context $storageAccount.Context).ICloudBlob.DownloadText()
Get-AzStorageBlob -Container $ContainerName -Blob $($policyName + ".json") -VersionId $versions[$versions.count - 2].VersionId -Context $storageAccount.Context | Get-AzStorageBlobContent -Path $tempFile.FullName -Force 
$oldBlob = (Get-Content -Path $tempFile.FullName)
$oldBlob = ($oldBlob -join "") | ConvertFrom-Json -Depth 100 | ConvertTo-Json -Depth 100
# Write to the Azure Functions log stream.
Import-Module "$($PSScriptRoot)\bin\DiffPlex.dll"
$differ = New-Object DiffPlex.Differ
$sideBySideBuilder = New-Object DiffPlex.DiffBuilder.SideBySideDiffBuilder($differ)

$oldReportTmp = New-TemporaryFile
$newReportTmp = New-TemporaryFile
$report = $sideBySideBuilder.BuildDiffModel($newBlob,$oldBlob)
$report.OldText.Lines | Out-File -FilePath $oldReportTmp.FullName -Force
$report.NewText.Lines | Out-File -FilePath $newReportTmp.FullName -Force

Set-AzStorageBlobContent -File $oldReportTmp.FullName -Container $ContainerName -Blob $($policyName + "-DifVersion-" + $versions[-1].VersionId.Replace(":","_") + "-" + $versions[$versions.count -2].VersionId.Replace(":","_") + "-OLDTEXT.json") -Context $storageAccount.Context -Force
Set-AzStorageBlobContent -File $newReportTmp.FullName -Container $ContainerName -Blob $($policyName + "-DifVersion-" + $versions[-1].VersionId.Replace(":","_") + "-" + $versions[$versions.count -2].VersionId.Replace(":","_") + "-NEWTEXT.json") -Context $storageAccount.Context -Force
