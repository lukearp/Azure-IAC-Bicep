$policyAssignmentName = "$($env:PolicyAssignmentName)"

$storageAccounts = (Get-AzPolicyState -PolicyAssignmentName $policyAssignmentName | ?{$_.ComplianceState -ne "Compliant"}).ResourceId
foreach($storageAccount in $storageAccounts){
    Select-AzSubscription -Subscription $storageAccount.Split("/")[2]
    New-AzStorageAccountKey -ResourceGroupName $storageAccount.Split("/")[4] -Name $storageAccount.Split("/")[8] -KeyName key1
    New-AzStorageAccountKey -ResourceGroupName $storageAccount.Split("/")[4] -Name $storageAccount.Split("/")[8] -KeyName key2
}