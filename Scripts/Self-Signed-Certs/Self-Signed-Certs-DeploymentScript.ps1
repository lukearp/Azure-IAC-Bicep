param(
    [Parameter(Mandatory=$true)]
    [string]$RootcertName,
    [Parameter(Mandatory=$true)]
    [array]$DNSNames,
    [Parameter(Mandatory=$true)]
    [string]$certPassword,
    [switch]$UploadToKeyVault,
    [string]$keyVaultResourceId = ''
)
$certsBase64 = @()

$rootcert = New-SelfSignedCertificate -CertStoreLocation cert:\CurrentUser\My -DnsName $RootcertName -KeyUsage CertSign
Export-Certificate -Cert $rootcert -FilePath ".\$($RootcertName).cer"
$rootcertContent = get-content ".\$($RootcertName).cer" -Encoding Byte
$certsBase64 += New-Object -TypeName psobject -Property @{
    certname = $RootcertName
    base64 = [System.Convert]::ToBase64String($rootcertContent)
}

$certs = @()
foreach($dns in $DNSNames)
{
    $certs += New-SelfSignedCertificate -certstorelocation cert:\CurrentUser\My -dnsname $dns -Signer $rootcert
}
$secureString = ConvertTo-SecureString -String $certPassword -Force -AsPlainText
foreach($cert in $certs)
{
    Export-PfxCertificate -Cert $cert -Password $secureString -FilePath ".\$($cert.SubjectName).pfx" -CryptoAlgorithmOption TripleDES_SHA1
    $certContent = get-content ".\$($cert.SubjectName).pfx" -Encoding Byte
    $certsBase64 += New-Object -TypeName psobject -Property @{
        certname = $cert.SubjectName
        base64 = [System.Convert]::ToBase64String($certContent)
    }
}

if($UploadToKeyVault)
{
    $infraContext = Connect-AzAccount -Identity -ContextName "infra" -SubscriptionId $keyVaultResourceId.Split("/")[2];
    $keyVaultName = $keyVaultResourceId.Split("/")[8]
    Set-AzKeyVaultSecret -VaultName $keyVaultName -Name $RootcertName -SecretValue $(ConvertTo-SecureString -AsPlainText -String ($rootcertContent = get-content ".\$($RootcertName).cer" -Encoding Byte) -Force);
    foreach($cert in $certs)
    {
        Import-AzKeyVaultCertificate -VaultName $keyVaultName -Name $cert.SubjectName -FilePath ".\$($cert.SubjectName).pfx" -Password $secureString
    }
}

$DeploymentScriptOutputs = @{};
$DeploymentScriptOutputs['certificates'] = $certsBase64