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

$sharedDisks = Search-AzGraph -Query $sharedDisksQuery

$sharedDiskVms = @()

foreach ($disk in $sharedDisks) {
    $sharedDiskVms += Search-AzGraph -Query $($vmsWithSharedDisksQuery -f $disk.DiskId)
}
$disks = $sharedDiskVms.OsDisk.manageddisk.id
$disks += $sharedDiskVms.DataDisks.manageddisk.id
$backupVaults = Get-AzDataProtectionBackupVault
$disks = $disks | Select -Unique
$instances = @()
foreach ($backupVault in $backupVaults) {
    $instances += Get-AzDataProtectionBackupInstance -VaultName $backupVault.Name -ResourceGroupName $backupVault.Id.Split("/")[4]
}

foreach ($disk in $disks) {
    $tags = (Get-AzResource -ResourceId $disk).Tags
    if ($tags -eq $null) {
        $tags = [System.Collections.Generic.Dictionary[String, String]]::new()
    }

    if ($($instances | ? { $_.property.DataSourceInfo.ResourceId -eq $disk }).count -eq 0) {
        
        if ($tags.Keys -notcontains "DiskBackupNeeded") {
            $tags.Add("DiskBackupNeeded", "true")
        }
    }
    else {
        if ($tags.Keys -notcontains "DiskBackupNeeded") {
            $tags.Add("DiskBackupNeeded", "false")
        } 
        else {
            $tags.DiskBackupNeeded = "false"
        }
    }
    Set-AzResource -ResourceId $disk -Tag $tags -Force -Confirm:$false
}