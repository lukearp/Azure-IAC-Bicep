# Variables To Change
$vmResourceGroup = ""
$recoveryResourceGroupId = ""
#

$resourceGroupName = "Site-recovery-vault-RG"
$FabricName = "asr-a2a-default-westus"
$PCName = "asr-a2a-default-westus-container"
$PCMName = "eastus-westus-24-hour-retention-policy"
$vaultName = "Site-recovery-vault-westus"
$cacheStorageAccountId = "/subscriptions//resourceGroups/site-recovery-vault-rg/providers/Microsoft.Storage/storageAccounts/u07tcqsiterecovasrcache"
$driveEncryptionSetId = "/subscriptions//resourceGroups/ADCONNECT-asr/providers/Microsoft.Compute/diskEncryptionSets/test"


# Get the Recovery Services vault
$vault = Get-AzRecoveryServicesVault -ResourceGroupName $resourceGroupName -Name $vaultName

# Set the vault context
Set-AzRecoveryServicesAsrVaultContext -Vault $vault
$fabric = Get-AzRecoveryServicesAsrFabric -Name $FabricName
$pc = Get-AzRecoveryServicesAsrProtectionContainer -Fabric $fabric -Name $PCName
$pcm = Get-AzRecoveryServicesAsrProtectionContainerMapping -ProtectionContainer $pc | ?{$_.Name -eq $PCMName}
# Get all VMs in the resource group
$vms = Get-AzVM -ResourceGroupName $vmResourceGroup -Status | ?{$_.PowerState -ne "VM deallocated" -and $_.Tags["DR"] -eq "yes"}

# Loop through each VM and enable replication
foreach ($vm in $vms) {
    # Get the VM's resource ID
    $vmId = $vm.Id
    $diskReplicationConfigs = @()
    $diskReplicationConfigs += New-AzRecoveryServicesAsrAzureToAzureDiskReplicationConfig -ManagedDisk -DiskId $vm.StorageProfile.OsDisk.ManagedDisk.Id -RecoveryResourceGroupId $recoveryResourceGroupId -RecoveryReplicaDiskAccountType $vm.StorageProfile.OsDisk.ManagedDisk.StorageAccountType -RecoveryTargetDiskAccountType $vm.StorageProfile.OsDisk.ManagedDisk.StorageAccountType -LogStorageAccountId $cacheStorageAccountId -RecoveryDiskEncryptionSetId $driveEncryptionSetId
    foreach($dataDisk in $vm.StorageProfile.DataDisks)
    {
        $diskReplicationConfigs += New-AzRecoveryServicesAsrAzureToAzureDiskReplicationConfig -ManagedDisk -DiskId $dataDisk.ManagedDisk.Id -RecoveryResourceGroupId $recoveryResourceGroupId -RecoveryReplicaDiskAccountType $dataDisk.ManagedDisk.StorageAccountType -RecoveryTargetDiskAccountType $dataDisk.ManagedDisk.StorageAccountType -LogStorageAccountId $cacheStorageAccountId -RecoveryDiskEncryptionSetId $driveEncryptionSetId
    }
    # Enable replication for the VM
    New-AzRecoveryServicesAsrReplicationProtectedItem -AzureToAzure -AzureToAzureDiskReplicationConfiguration $diskReplicationConfigs -AzureVmId $vmId -Name $vm.Name.tolower() -ProtectionContainerMapping $pcm -RecoveryResourceGroupId $recoveryResourceGroupId
}

Write-Output "Replication enabled for all VMs in the resource group."