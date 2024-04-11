$sharedDisksQuery = @'
resources
| where type =~ "Microsoft.Compute/disks"
| where properties.maxShares > 0
| project name, properties.maxShares, DiskId=id
'@

$vmsWithSharedDisksQuery = @'
resources
| where type =~ "Microsoft.Compute/virtualMachines"
| project name, DataDisks=properties.storageProfile.dataDisks, OSDisk=properties.storageProfile.osDisk
| where DataDisks contains "{0}"
'@

$backupVaultsGraphQuery = @'
resources
| where type =~ "Microsoft.DataProtection/BackupVaults"
| project name, resourceGroup, subscriptionId
'@

$backupPolicyPolicyRules = @'
[
      {
        "IsDefault": true,
        "Lifecycle": [
          {
            "DeleteAfterDuration": "P30D",
            "DeleteAfterObjectType": "AbsoluteDeleteOption",
            "SourceDataStoreObjectType": "DataStoreInfoBase",
            "SourceDataStoreType": {},
            "TargetDataStoreCopySetting": []
          }
        ],
        "Name": "Default",
        "ObjectType": "AzureRetentionRule"
      },
      {
        "BackupParameter": {
          "BackupType": "Incremental",
          "ObjectType": "AzureBackupParams"
        },
        "BackupParameterObjectType": "AzureBackupParams",
        "DataStoreObjectType": "DataStoreInfoBase",
        "DataStoreType": {},
        "Name": "BackupDaily",
        "ObjectType": "AzureBackupRule",
        "Trigger": {
          "ObjectType": "ScheduleBasedTriggerContext",
          "ScheduleRepeatingTimeInterval": [
            "R/2024-04-10T22:00:00-05:00/P1D"
          ],
          "ScheduleTimeZone": "Eastern Standard Time",
          "TaggingCriterion": [
            {
              "Criterion": null,
              "IsDefault": true,
              "TagInfoETag": null,
              "TagInfoId": "Default_",
              "TagInfoTagName": "Default",
              "TaggingPriority": 99
            }
          ]
        },
        "TriggerObjectType": "ScheduleBasedTriggerContext"
      }
    ]
'@

$sharedDisks = Search-AzGraph -Query $sharedDisksQuery

$sharedDiskVms = @()

foreach ($disk in $sharedDisks) {
    $sharedDiskVms += Search-AzGraph -Query $($vmsWithSharedDisksQuery -f $disk.DiskId)
}
$disks = $sharedDiskVms.OsDisk.manageddisk.id
$disks += $sharedDiskVms.DataDisks.manageddisk.id
$backupVaults = Search-AzGraph -Query $backupVaultsGraphQuery
$disks = $disks | Select -Unique
$instances = @()
foreach ($backupVault in $backupVaults) {
    Select-AzSubscription $backupVault.subscriptionId
    $instances += Get-AzDataProtectionBackupInstance -VaultName $backupVault.name -ResourceGroupName $backupVault.resourceGroup
}

foreach ($disk in $disks) {
    $diskInfo = Get-AzResource -ResourceId $disk | Select Tags, Location
    if ($diskInfo.tags -eq $null) {
        $diskInfo.tags = [System.Collections.Generic.Dictionary[String, String]]::new()
    }
    if ($($instances | ? { $_.property.DataSourceInfo.ResourceId -eq $disk }).count -eq 0) {
        
        if ($diskInfo.tags.Keys -notcontains "DiskBackupNeeded") {
            $diskInfo.tags.Add("DiskBackupNeeded", "true")
        }
        else {
            $diskInfo.tags.DiskBackupNeeded = "true"
        }
        $subscription = Get-AzSubscription -SubscriptionId $($disk.split("/")[2])
        $vault = $backupVaults | ?{$_.subscriptionId -eq "*$($disk.split("/")[2])*" -and $_.name -eq "ad-bv-$($subscription.Name.Replace("_","-"))"}
        if($null -eq $vault)
        {
            Select-AzSubscription -Subscription $subscription.Id
            $storageSetting = New-AzDataProtectionBackupVaultStorageSettingObject -Type GeoRedundant -DataStoreType VaultStore
            $newVault = New-AzDataProtectionBackupVault -ResourceGroupName "rg_backup" -VaultName "ad-bv-$((Get-AzSubscription -SubscriptionId $disk.split("/")[2]).Name.Replace("_","-"))" -Location $diskInfo.Location -StorageSetting $storageSetting
            New-AzRoleAssignment -ObjectId $newVault.Identity.PrincipalId -Scope "/subscriptions/$($subscription.Id)" -RoleDefinitionId "3e5e47e6-65f7-47ef-90b5-e5dd4d455f24"
            New-AzRoleAssignment -ObjectId $newVault.Identity.PrincipalId -Scope "/subscriptions/$($subscription.Id)/resourceGroups/rg_backup" -RoleDefinitionId "7efff54f-a5b4-42b5-a1c5-5411624893ce"
            $backupVaults += New-Object -typename psobject -Property @{
                name = $newVault.VaultName
                resourceGroup = $newVault.ResourceGroupName
                subscriptionId = $newVault.SubscriptionId
            }
            $defaultPol = Get-AzDataProtectionPolicyTemplate -DatasourceType AzureDisk 
            $defaultPol.PolicyRule[0].Trigger.ScheduleTimeZone = "Eastern Standard Time"
            $defaultPol.PolicyRule[0].Trigger.ScheduleRepeatingTimeInterval = @("R/2024-04-10T22:00:00-05:00/P1D") 
            $defaultPol.PolicyRule[1].Lifecycle[0].DeleteAfterDuration = "P30D"
            $diskBackupPolicy = New-AzDataProtectionBackupPolicy -ResourceGroupName "rg_backup" -VaultName $newVault.Name -Name "defaultPolicy" -Policy $defaultPol
        }
        $vault = Get-AzDataProtectionBackupVault -VaultName "ad-bv-$((Get-AzSubscription -SubscriptionId $disk.split("/")[2]).Name.Replace("_","-"))" -ResourceGroupName "rg_backup"
        $diskPolicy = Get-AzDataProtectionBackupPolicy -Name "defaultPolicy" -ResourceGroupName "rg_backup" -VaultName $vault.Name
        $instance = Initialize-AzDataProtectionBackupInstance -DatasourceType AzureDisk -DatasourceLocation $diskInfo.Location -PolicyId $diskPolicy.Id -DatasourceId $disk
        $instance.Property.PolicyInfo.PolicyParameter.DataStoreParametersList[0].ResourceGroupId = "/subscriptions/$($subscription.Id)/resourceGroups/rg_backup"
        try {
          New-AzDataProtectionBackupInstance -ResourceGroupName "rg_backup" -VaultName $vault.Name -BackupInstance $instance
          $diskInfo.tags.DiskBackupNeeded = "false"
        }
        catch {

        }
        #Backup-AzDataProtectionBackupInstanceAdhoc -BackupInstanceName $instance.BackupInstanceName -ResourceGroupName "rg_backup" -VaultName $vault.Name -BackupRuleOptionRuleName "Default"
    }
    else {
        if ($diskInfo.tags.Keys -notcontains "DiskBackupNeeded") {
            $diskInfo.tags.Add("DiskBackupNeeded", "false")
        } 
        else {
            $diskInfo.tags.DiskBackupNeeded = "false"
        }
    }
    New-AzTag -ResourceId $disk -Tag $diskInfo.tags -Force -Confirm:$false
}