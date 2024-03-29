$keyVaultSecrets = @(
    "https://<keyvaultname>.vault.azure.net:443/secrets/<certificatename>/",
    "https://<keyvaultname>.vault.azure.net:443/secrets/<certificatename>/"
)
$managedIdentity = "<Managed-Identity-ResourceID>"
$applicationGateways = Search-AzGraph -UseTenantScope -Query "resources | where type contains `"applicationGateways`" | project id"; 
foreach ($applicationGateway in $applicationGateways) {
    $subscription = $applicationGateway.id.split("/")[2]
    $resourceGroup = $applicationGateway.id.split("/")[4]
    $appGatewayName = $applicationGateway.id.split("/")[8]

    Select-AzSubscription -Subscription $subscription
    $appGw = Get-AzApplicationGateway -Name $appGatewayName -ResourceGroupName $resourceGroup
    if ($appGw.Identity -eq $null) {
        Set-AzApplicationGatewayIdentity -ApplicationGateway $appGw -UserAssignedIdentityId $managedIdentity
    }
    $existCount = 0;
    foreach ($keyVaultSecret in $keyVaultSecrets) {
        if ($appGw.SslCertificates.Count -gt 0) {
            if ($appGw.SslCertificates.Name.ToUpper().contains($($keyVaultSecret.Split("/")[4] + "-kv").ToUpper())) {
                Write-Host "Cert already assigned";
                $existCount++;
            }
            else {
                Add-AzApplicationGatewaySslCertificate -ApplicationGateway $appGw -Name $($keyVaultSecret.Split("/")[4] + "-kv").ToUpper() -KeyVaultSecretId $keyVaultSecret
            }
        }
        else {
            Add-AzApplicationGatewaySslCertificate -ApplicationGateway $appGw -Name $($keyVaultSecret.Split("/")[4] + "-kv").ToUpper() -KeyVaultSecretId $keyVaultSecret
        }
    }
    if($existCount -ne $keyVaultSecrets.Count)
    {
        Set-AzApplicationGateway -ApplicationGateway $appGw
    }
    $existCount = 0;
}