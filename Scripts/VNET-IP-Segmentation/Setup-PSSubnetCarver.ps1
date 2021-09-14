param (
    $uri
)

Invoke-WebRequest -Uri $uri -OutFile "PSSubnetCarver.zip"
Expand-Archive .\PSSubnetCarver.zip -DestinationPath .\PSSubnetCarver
Import-Module .\PSSubnetCarver\