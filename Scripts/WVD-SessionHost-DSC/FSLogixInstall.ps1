param (
    [string]$uncPath
)
Expand-Archive -Path $($ScriptPath +"\FSLogix.zip") -Force -DestinationPath $($ScriptPath +"\FSLogix");
$exeLocation = $($ScriptPath + "\FSLogix\x64\Release");
Start-Process -FilePath $($exeLocation + "\FSLogixAppsSetup.exe") -ArgumentList "/install /quiet" -Verb runas -Wait;
New-Item -Path HKLM:\SOFTWARE\FSLogix\Profiles
New-ItemProperty -Path HKLM:\SOFTWARE\FSLogix\Profiles -Name Enabled -PropertyType DWord -Value 1
New-ItemProperty -Path HKLM:\SOFTWARE\FSLogix\Profiles -Name DeleteLocalProfileWhenVHDShouldApply -PropertyType DWord -Value 1
New-ItemProperty -Path HKLM:\SOFTWARE\FSLogix\Profiles -Name VHDLocations -PropertyType MultiString -Value @($uncPath)