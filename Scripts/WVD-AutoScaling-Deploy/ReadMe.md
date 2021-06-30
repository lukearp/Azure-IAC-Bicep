#How to create Azure Automation Account

```dotnetcli
New-Item -ItemType Directory -Path "C:\Temp" -Force
Set-Location -Path "C:\Temp"
$Uri = "https://raw.githubusercontent.com/lukearp/Azure-IAC-Bicep/master/Scripts/WVD-AutoScaling-Deploy/CreateOrUpdateAzAutoAccount.ps1"
# Download the script
Invoke-WebRequest -Uri $Uri -OutFile ".\CreateOrUpdateAzAutoAccount.ps1"
```

#How to create Logic App for Scaling

```dotnetcli
New-Item -ItemType Directory -Path "C:\Temp" -Force
Set-Location -Path "C:\Temp"
$Uri = "https://raw.githubusercontent.com/lukearp/Azure-IAC-Bicep/master/Scripts/WVD-AutoScaling-Deploy/CreateOrUpdateAzLogicApp.ps1"
# Download the script
Invoke-WebRequest -Uri $Uri -OutFile ".\CreateOrUpdateAzLogicApp.ps1"
```