param($Timer)

$keyVaultName = "luke-encryption-2025"
$keyVaultResourceGroup = "vnet-hub-2025"
$keyVaultSubscription = "32eb88b4-4029-4094-85e3-ec8b7ce1fc00"
$targetVault = "luke-west-cmk"
$backupToBlob = $true
$targetStorageAccountId = "/subscriptions/32eb88b4-4029-4094-85e3-ec8b7ce1fc00/resourceGroups/luke-storage-public/providers/Microsoft.Storage/storageAccounts/lukestoragetest"
$containerName = "luketest"
$backupSecrets = $true
$backupCertificates = $true
$backupKeys = $true

$storageName = $targetStorageAccountId.Split("/")[8]
$storageRg = $targetStorageAccountId.Split("/")[4]
$storageSub = $targetStorageAccountId.Split("/")[2]

Select-AzSubscription -Subscription $storageSub
$storageAccount = Get-AzStorageAccount -Name $storageName -ResourceGroupName $storageRg

Select-AzSubscription $keyVaultSubscription

New-Item -ItemType Directory -Path .\Backups -Force -ErrorAction SilentlyContinue

$keyVault = Get-AzKeyVault -Name $keyVaultName -ResourceGroupName $keyVaultResourceGroup
$secrets = @()
$certificates = @()
$keys = @()
if ($backupSecrets) {
    $secrets = Get-AzKeyVaultSecret -VaultName $keyVault.VaultName
}
if ($backupCertificates) {
    $certificates = Get-AzKeyVaultCertificate -VaultName $keyVault.VaultName
}
if ($backupKeys) {
    $keys = Get-AzKeyVaultKey -VaultName $keyVault.VaultName
}

foreach ($secret in $secrets) {    
    if ($secret.Tags.Count -eq 0) {
        $secret.Tags = @{
            "Backup" = ""
        }
    } 
    if ($secret.Tags["Backup"] -ne $secret.Created.Date.ToString("yyyy-MM-dd-hh-mm-ss")) {
        Backup-AzKeyVaultSecret -Name $secret.Name -VaultName $keyVault.VaultName -OutputFile ".\Backups\secret-$($secret.Name)-$($keyVaultSubscription)-$($secret.Created.Date.ToString("yyyy-MM-dd-hh-mm-ss"))" -ErrorAction SilentlyContinue
         
        if ($secret.Tags["Backup"] -eq $null) {
            $secret.Tags.Add("Backup", $secret.Created.Date.ToString("yyyy-MM-dd-hh-mm-ss"))
        }
        else {
            $secret.Tags["Backup"] = $secret.Created.Date.ToString("yyyy-MM-dd-hh-mm-ss")
        }
        Set-AzKeyVaultSecretAttribute -Name $secret.Name -VaultName $keyVault.VaultName -Tag $secret.Tags -ErrorAction SilentlyContinue
    }
}
foreach ($cert in $certificates) {
    if ($cert.Tags.Count -eq 0) {
        $cert.Tags = @{
            "Backup" = ""
        }
    } 
    if ($cert.Tags["Backup"] -ne $cert.Created.Date.ToString("yyyy-MM-dd-hh-mm-ss")) {
        Backup-AzKeyVaultCertificate -Name $cert.Name -VaultName $keyVault.VaultName -OutputFile ".\Backups\cert-$($cert.Name)-$($keyVaultSubscription)-$($cert.Created.Date.ToString("yyyy-MM-dd-hh-mm-ss"))"  -ErrorAction SilentlyContinue
        
        if ($cert.Tags["Backup"] -eq $null) {
            $cert.Tags.Add("Backup", $cert.Created.Date.ToString("yyyy-MM-dd-hh-mm-ss"))
        }
        else {
            $cert.Tags["Backup"] = $cert.Created.Date.ToString("yyyy-MM-dd-hh-mm-ss")
        }
        Set-AzKeyVaultCertificateAttribute -Name $cert.Name -VaultName $keyVault.VaultName -Tag $cert.Tags -ErrorAction SilentlyContinue
    }
}
foreach ($key in $keys) {
    if ($key.Tags.Count -eq 0) {
        $key.Tags = @{
            "Backup" = ""
        }
    } 
    if ($key.Tags["Backup"] -ne $key.Created.Date.ToString("yyyy-MM-dd-hh-mm-ss")) {
        Backup-AzKeyVaultKey -Name $key.Name -VaultName $keyVault.VaultName -OutputFile ".\Backups\key-$($key.Name)-$($keyVaultSubscription)-$($key.Created.Date.ToString("yyyy-MM-dd-hh-mm-ss"))"  -ErrorAction SilentlyContinue
        
        if ($key.Tags["Backup"] -eq $null) {
            $key.Tags.Add("Backup", $key.Created.Date.ToString("yyyy-MM-dd-hh-mm-ss"))
        }
        else {
            $key.Tags["Backup"] = $key.Created.Date.ToString("yyyy-MM-dd-hh-mm-ss")
        }
        Set-AzKeyVaultKeyAttribute -Name $key.Name -VaultName $keyVault.VaultName -Tag $key.Tags -ErrorAction SilentlyContinue
    }
}

$items = Get-ChildItem -Path ".\Backups"
foreach ($item in $items) {
    if($backupToBlob -eq $false)
    {
        switch($item.Name)
        {
           {$_ -like "secret-*"} {
            Restore-AzKeyVaultSecret -VaultName $targetVault -InputFile $item.FullName
           } 
           {$_ -like "cert-*"} {
            Restore-AzKeyVaultCertificate -VaultName $targetVault -InputFile $item.FullName
           }
           {$_ -like "key-*"} {
            Restore-AzKeyVaultKey -VaultName $targetVault -InputFile $item.FullName
           }
        }    
    }
    else {
        Set-AzStorageBlobContent -File $item.FullName -Container $containerName -Blob $item.Name -Context $storageAccount.Context 
    }
}
Remove-Item -Path .\Backups -Recurse -Force