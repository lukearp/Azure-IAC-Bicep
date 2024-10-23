#Connect-AzAccount
param (
    $SubscriptionId,
    $ResourceGroupName,
    $VMName,
    [ValidateSet("StandardSSD_ZRS","PremiumSSD_ZRS")]
    $DiskSku,
    [switch]$replaceExisting,
    [switch]$powerDownExisting
)

Select-AzSubscription -SubscriptionId $SubscriptionId
$vms = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VMName
# Stop the VM before moving it
$vmObjects = @()
foreach($vm in $vms)
{
    $Region = $vm.Location
    if($replaceExisting -or $powerDownExisting)
    {
        Stop-AzVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name -Force
    }
    $vm.StorageProfile.ImageReference = $null
    $vm.OSProfile = $null
    # Take a snapshot of the current disk
    $snapshots = @()
    $suffix = [datetime]::UtcNow.ToString("yyyy-MM-dd-") + $(New-Guid).Guid.Substring(4,8) + "-snapshot"
    $snapshotConfig = New-AzSnapshotConfig -SourceResourceId $vm.StorageProfile.OsDisk.ManagedDisk.Id -Location $Region -CreateOption Copy
    $snapshots += New-AzSnapshot -Snapshot $snapshotConfig -SnapshotName ($vm.Name + "-OSDisk-" + $suffix) -ResourceGroupName $ResourceGroupName
    $count = 0
    foreach($dataDisk in $vm.StorageProfile.DataDisks)
    {
        $snapshotConfig = New-AzSnapshotConfig -SourceResourceId $dataDisk.ManagedDisk.Id -Location $Region -CreateOption Copy
        $snapshots += New-AzSnapshot -Snapshot $snapshotConfig -SnapshotName ($vm.Name + "-DataDisk$($count)-" + $suffix) -ResourceGroupName $ResourceGroupName
        $count++
    }
    # Create a new managed disk from the snapshot
    $disks = @()
    foreach($snapshot in $snapshots)
    {
        $diskConfig = New-AzDiskConfig -Location $Region -SourceResourceId $snapshot.Id -CreateOption Copy -SkuName $DiskSku
        $disks += New-AzDisk -Disk $diskConfig -ResourceGroupName $ResourceGroupName -DiskName $snapshot.Name.Replace("-snapshot","-regional") 
    }
    
    # Update the VM's OS disk with the new disk
    $count = 0
    foreach ($disk in $disks)
    {
        if($count -eq 0)
        {
            $vm.StorageProfile.OsDisk.ManagedDisk.Id = $disk.Id
            $vm.StorageProfile.OsDisk.Name = $disk.Name
            $vm.StorageProfile.OsDisk.DeleteOption = "Detach"
        }
        else {
            $vm.StorageProfile.DataDisks[($count - 1)].ManagedDisk.Id = $disk.Id
            $vm.StorageProfile.DataDisks[($count - 1)].Name = $disk.Name
            $vm.StorageProfile.DataDisks[($count - 1)].DeleteOption = "Detach"
        }
        $count++
    }    
    for($i = 0; $i -lt $vm.NetworkProfile.NetworkInterfaces.Count; $i++)
    {
        $vm.NetworkProfile.NetworkInterfaces[$i].DeleteOption = "Detach"
    } 
    if($replaceExisting)
    {
        Update-AzVM -ResourceGroupName $ResourceGroupName -VM $vm
    } 
    $count = 0
    foreach ($disk in $disks)
    {
        if($count -eq 0)
        {
            $vm.StorageProfile.OsDisk.ManagedDisk.Id = $disk.Id
            $vm.StorageProfile.OsDisk.CreateOption = "Attach"
            $vm.StorageProfile.OsDisk.Name = $disk.Name
            $vm.StorageProfile.OsDisk.DeleteOption = "Detach"
        }
        else {
            $vm.StorageProfile.DataDisks[($count - 1)].ManagedDisk.Id = $disk.Id
            $vm.StorageProfile.DataDisks[($count - 1)].CreateOption = "Attach"
            $vm.StorageProfile.DataDisks[($count - 1)].Name = $disk.Name
            $vm.StorageProfile.DataDisks[($count - 1)].DeleteOption = "Detach"
        }
        $count++
    }  
    $vm.Zones = $null
    if($replaceExisting -ne $true)
    {
        $vm.Name = $vm.Name + "-zrs"    
        $nics = @()
        foreach($nic in $vm.NetworkProfile.NetworkInterfaces)
        {
            $thisNic = Get-AzNetworkInterface -Name $nic.Id.Split("/")[8] -ResourceGroupName $ResourceGroupName
            $nics += New-AzNetworkInterface -Name $($nic.Id.Split("/")[8] + "-" + $(New-Guid).Guid.Substring(4,8) + "-zrs") -SubnetId $thisNic.IpConfigurations[0].Subnet.Id -ResourceGroupName $ResourceGroupName -Location $Region
        }
        $count = 0
        foreach($nic in $nics)
        {
            $vm.NetworkProfile.NetworkInterfaces[$count].Id = $nic.Id
            $count++
        }
        $vmObjects += $vm | Select-Object -ExcludeProperty Id,ResourceGroupName,TimeCreated,Etag
    }
    else {
        #Update-AzVM -ResourceGroupName $ResourceGroupName -VM $vm
        Remove-AzVM -Name $vm.Name -ResourceGroupName $vm.ResourceGroupName -Force
        $vmObjects += $vm | Select-Object -ExcludeProperty Id,ResourceGroupName,TimeCreated,Etag
    }
    if($null -eq $vm.LicenseType)
    {
        $newVM = $vm | Select-Object -ExcludeProperty Id,ResourceGroupName,TimeCreated,LicenseType,Etag
    }
    else {
        $newVM = $vm | Select-Object -ExcludeProperty Id,ResourceGroupName,TimeCreated,Etag
    }
    New-AzVM -ResourceGroupName $ResourceGroupName -VM $newVM -Location $Region -Tag $vm.Tags
}
$vmObjects | ConvertTo-Json -Depth 100 | Out-File -FilePath .\report.json