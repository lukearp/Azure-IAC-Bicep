using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)
$ContainerName = $env:ContainerName #"Storage Container Name"
$StorageAccountName = $env:StorageAccountName #"Storage Account Name"
$StorageAccountResourceGroupName = $env:StorageAccountResourceGroupName #Resource Group of Storage Account"
$StorageAccountSubscription = $env:StorageAccountSubscription #"Subscription of storage account"
$testing = $env:Testing #$true for True $false for False
$testFirewallPolicyId = $env:TestFirewallPolicy # Resource ID of test firewall policy

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

Select-AzSubscription -Subscription $StorageAccountSubscription
$storageAccount = Get-AzStorageAccount -Name $StorageAccountName -ResourceGroupName $StorageAccountResourceGroupName

$versions = Get-AzStorageBlob -Blob $($policyName + ".json") -Container $ContainerName -Context $storageAccount.Context -IncludeVersion
# Write to the Azure Functions log stream.
$differ = New-Object DiffPlex.Differ
$sideBySideBuilder = New-Object DiffPlex.DiffBuilder.SideBySideDiffBuilder($differ)
$old = ConvertFrom-Json -InputObject $((Get-Content -Path '.\File1.json')-join "") -Depth 100
$new = ConvertFrom-Json -InputObject $((Get-Content -Path '.\File2.json')-join "") -Depth 100
$newTextLines = Get-Content -Path '.\File2.json'
# OldText will show Deletes - NewText will show Modified - NewText will signal Deletes have happened with lines marked Imaginary
$report = $sideBySideBuilder.BuildDiffModel($(ConvertTo-Json -InputObject $old -Depth 100),$(ConvertTo-Json -InputObject $new -Depth 100))
$changesInNew = $report.NewText.Lines | ?{$_.Type -ne "Unchanged"}
if(($changesInNew | ?{$_.Type -eq "Imaginary"}).count -eq 0)
{
    Write-Output "Deletes Detected"
    $lines = $changesInNew.Position
    foreach($line in $lines)
    {
        $startObjectLine = 0
        $endObjectLine = 0
        if($newTextLines[$line - 1] -ne "{" -or $newTextLines[$line - 1] -ne "}")
        {
            for($i = $line - 1; $i -gt 0; $i--)
            {
                if($newTextLines[$i] -like "*{*")
                {
                    $startObjectLine = $i
                    break
                }
            }
            for($i = $line - 1; $i -lt $newTextLines.count; $i++)
            {
                if($newTextLines[$i] -like "*}*")
                {
                    $endObjectLine = $i
                    break
                }
            }
        }
    }
}