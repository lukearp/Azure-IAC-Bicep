param($source,$dest)

while($true)
{
    $items = Get-ChildItem -Path $source
    foreach($item in $items)
    {
        Move-Item -Path $item.FullName -Destination $dest
    }
    Start-Sleep -Seconds 5;
}