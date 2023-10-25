param (
    [string]$externalWildcard,
    [string]$internalWildcard,
    [string]$vaultName
)

Connect-AzAccount -Identity
Start-Process -FilePath openssl -ArgumentList "genrsa -out ca.key 2048" -Wait
$caReq = "req -x509 -new -nodes -key ca.key -subj `"/CN=ESRI-TEMP/C=US/L=CALIFORNIA`" -days 1825 -out ca.crt"
Start-Process -FilePath openssl -ArgumentList $caReq -Wait
$externalWildcardKey = "genrsa -out externalWildcard.key 2048"
Start-Process -FilePath openssl -ArgumentList $externalWildcardKey -Wait
$config = @'
[ req ]
default_bits = 2048
prompt = no
default_md = sha256
req_extensions = req_ext
distinguished_name = dn

[ dn ]
C = US
ST = California
L = TEMP
O = TEMP
OU = TEMP
CN = esritemp.test.com

[ req_ext ]
subjectAltName = @alt_names

[ alt_names ]
DNS.1 = {0}
'@
$configParsed = $config -f $externalWildcard
$configParsed | Out-File external-csr.conf
$externalWildcardRequest = "req -new -key externalWildcard.key -out externalWildcard.csr -config external-csr.conf"
Start-Process -FilePath openssl -ArgumentList $externalWildcardRequest -Wait
$externalWildcardSigning = "x509 -req -in externalWildcard.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out externalWildcard.crt -days 10000 -extfile external-csr.conf -extensions req_ext"
Start-Process -FilePath openssl -ArgumentList $externalWildcardSigning -Wait
$externalPfxCreate = "pkcs12 -export -out externalWildcard.pfx -inkey externalWildcard.key -in externalWildcard.crt -passout pass:"
Start-Process -FilePath openssl -ArgumentList $externalPfxCreate -Wait

$internalWildcardKey = "genrsa -out internalWildcard.key 2048"
Start-Process -FilePath openssl -ArgumentList $internalWildcardKey -Wait
$config = @'
[ req ]
default_bits = 2048
prompt = no
default_md = sha256
req_extensions = req_ext
distinguished_name = dn

[ dn ]
C = US
ST = California
L = TEMP
O = TEMP
OU = TEMP
CN = esritemp.test.com

[ req_ext ]
subjectAltName = @alt_names

[ alt_names ]
DNS.1 = {0}
'@
$configParsed = $config -f $internalWildcard
$configParsed | Out-File internal-csr.conf
$internalWildcardRequest = "req -new -key internalWildcard.key -out internalWildcard.csr -config internal-csr.conf"
Start-Process -FilePath openssl -ArgumentList $internalWildcardRequest -Wait
$internalWildcardSigning = "x509 -req -in internalWildcard.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out internalWildcard.crt -days 10000 -extfile internal-csr.conf -extensions req_ext"
Start-Process -FilePath openssl -ArgumentList $internalWildcardSigning -Wait
$internalPfxCreate = "pkcs12 -export -out internalWildcard.pfx -inkey internalWildcard.key -in internalWildcard.crt -passout pass:"
Start-Process -FilePath openssl -ArgumentList $internalPfxCreate -Wait
$rootCAContent = Get-Content -Path .\ca.crt
$rootCA = $rootCAContent.Replace("-----BEGIN CERTIFICATE-----","").Replace("-----END CERTIFICATE-----","") -join ""
Set-AzKeyVaultSecret -VaultName $vaultName -Name "ss-root" -SecretValue $(ConvertTo-SecureString -String $rootCA -AsPlainText -Force) 
Import-AzKeyVaultCertificate -VaultName $vaultName -Name external-temp -FilePath .\externalWildcard.pfx
Import-AzKeyVaultCertificate -VaultName $vaultName -Name internal-temp -FilePath .\internalWildcard.pfx