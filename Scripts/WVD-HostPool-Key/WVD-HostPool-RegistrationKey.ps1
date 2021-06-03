param(
    [string]$appId,
    [string]$AppSecretId,
    [string]$tenantId,
    [string]$keyVaultId,
    [string]$secretName,
    [string]$hostPoolResourceId
)
Connect-AzAccount -Identity -ContextName "infra"
$secret = Get-AzKeyVaultSecret -VaultName $keyVaultId.Split('/')[8] -Name $secretName
$creds = New-Object System.Management.Automation.PSCredential ($appId,$secret.SecretValue)
Connect-AzAccount -Tenant $tenantId -Credential $creds -ServicePrincipal -ContextName "wvd"
Set-AzContext -Name "wvd"
$registrationKey = Get-AzWvdRegistrationInfo -SubscriptionId $hostPoolResourceId.Split('/')[2] -ResourceGroupName $hostPoolResourceId.Split('/')[4] -HostPoolName $hostPoolResourceId.Split('/')[-1]