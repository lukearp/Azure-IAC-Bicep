param(
    [string]$appId,
    [string]$tenantId,
    [string]$keyVaultName,
    [string]$secretName,
    [string]$hostPoolResourceId
)
function Get-Token {
    param(
        [string]$appId,
        [string]$tenantId,
        [string]$keyVaultName,
        [string]$secretName,
        [string]$hostPoolResourceId
    )
    #$infraContext = Connect-AzAccount -Identity -ContextName "infra";
    $secret = Get-AzKeyVaultSecret -VaultName $keyVaultName -Name $secretName;
    $creds = New-Object System.Management.Automation.PSCredential ($appId, $secret.SecretValue);
    $wvdContext = Connect-AzAccount -TenantId $tenantId -Credential $creds -ServicePrincipal -ContextName "wvd" -Force -Confirm:$false;
    $set = Set-AzContext -Name "wvd" -Context $wvdContext.Context -Force -Confirm:$false;
    $registrationKey = Get-AzWvdRegistrationInfo -SubscriptionId $hostPoolResourceId.Split('/')[2] -ResourceGroupName $hostPoolResourceId.Split('/')[4] -HostPoolName $hostPoolResourceId.Split('/')[-1];
    $token = "";
    if ($registrationKey.ExpirationTime -lt (Get-Date)) {
        $token = (New-AzWvdRegistrationInfo -ExpirationTime $((get-date).ToUniversalTime().AddMinutes(61).ToString('yyyy-MM-ddTHH:mm:ss.fffffffZ')) -SubscriptionId $hostPoolResourceId.Split('/')[2] -ResourceGroupName $hostPoolResourceId.Split('/')[4] -HostPoolName $hostPoolResourceId.Split('/')[-1]).Token;
    }
    else {
        $token = $registrationKey.Token
    }

    return $token
}

return Get-Token -appId $appId -tenantId $tenantId -keyVaultName $keyVaultName -secretName $secretName -hostPoolResourceId $hostPoolResourceId