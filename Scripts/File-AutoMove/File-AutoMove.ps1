param($source,$dest)

while($true)
{
    $items = Get-ChildItem -Path $source
    foreach($item in $items)
    {
        try {
            Move-Item -Path $item.FullName -Destination $dest
        }
        catch {
            
        }
    }
    Start-Sleep -Seconds 5;
}