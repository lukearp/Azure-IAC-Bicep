param(
    $pathToJson,
    $pathToAzCopy,
    $storageAccountName,
    $sv
)
$filemapping = ConvertFrom-Json -InputObject ((Get-Content -Path $pathToJson) -join "");
foreach($filemap in $filemapping){
$storageTarget = "https://" + $storageAccountName + ".file.core.windows.net/" + $filemap.destShare + $sv;
Start-Process -FilePath "$($pathToAzCopy)" -ArgumentList "sync $($filemap.source) `"$($storageTarget)`" --preserve-permissions" -Wait;
}