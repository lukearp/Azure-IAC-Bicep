param(
    [Parameter(Mandatory=$true)]
    [string]$RootcertName,
    [Parameter(Mandatory=$true)]
    [array]$DNSNames,
    [Parameter(Mandatory=$true)]
    [string]$OutPath,
    [Parameter(Mandatory=$true)]
    [string]$certPassword,
    [switch]$UploadToKeyVault,
    [string]$keyVaultResourceId = ''
)

$rootcert = New-SelfSignedCertificate -CertStoreLocation cert:\CurrentUser\My -DnsName $RootcertName -KeyUsage CertSign
if($OutPath[-1] -eq "\")
{
    $OutPath = $OutPath
}
else {
    $OutPath = $OutPath + "\"
}
$checkIfPathExists = Get-Item -FilePath $OutPath -ErrorAction SilentlyContinue -Confirm:$false
if($checkIfPathExists -eq $null)
{
    New-Item -Path $OutPath -ItemType Directory
}
Export-Certificate -Cert $rootcert -FilePath $($OutPath + $RootcertName + ".cer")
$certs = @()
foreach($dns in $DNSNames)
{
    $certs += New-SelfSignedCertificate -certstorelocation cert:\CurrentUser\My -dnsname $dns -Signer $rootcert
}
$secureString = ConvertTo-SecureString -String $certPassword -Force -AsPlainText
foreach($cert in $certs)
{
    Export-PfxCertificate -Cert $cert -Password $secureString -FilePath $($OutPath + $cert.Subject + ".pfx") -CryptoAlgorithmOption TripleDES_SHA1
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