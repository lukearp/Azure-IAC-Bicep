param (
    [string]$uncPath
)
Expand-Archive -Path $($ScriptPath +"\FSLogix.zip") -Force -DestinationPath $($ScriptPath +"\FSLogix");
$exeLocation = $($ScriptPath + "\FSLogix\x64\Release");
Start-Process -FilePath $($exeLocation + "\FSLogixAppsSetup.exe") -ArgumentList "/install /quiet" -Verb runas -Wait;
if((Get-Item -Path HKLM:\SOFTWARE\FSLogix\Profiles -ErrorAction SilentlyContinue) -eq $null )
{
    New-Item -Path HKLM:\SOFTWARE\FSLogix\Profiles
}
if((Get-ItemProperty -Path HKLM:\SOFTWARE\FSLogix\Profiles -Name Enabled -ErrorAction SilentlyContinue) -eq $null )
{
    New-ItemProperty -Path HKLM:\SOFTWARE\FSLogix\Profiles -Name Enabled -PropertyType DWord -Value 1
}
else {
    Set-ItemProperty -Path HKLM:\SOFTWARE\FSLogix\Profiles -Name Enabled -Value 1 -Force -Confirm:$false
}
if((Get-ItemProperty -Path HKLM:\SOFTWARE\FSLogix\Profiles -Name DeleteLocalProfileWhenVHDShouldApply -ErrorAction SilentlyContinue) -eq $null )
{
    New-ItemProperty -Path HKLM:\SOFTWARE\FSLogix\Profiles -Name DeleteLocalProfileWhenVHDShouldApply -PropertyType DWord -Value 1
}
else {
    Set-ItemProperty -Path HKLM:\SOFTWARE\FSLogix\Profiles -Name DeleteLocalProfileWhenVHDShouldApply -Value 1 -Force -Confirm:$false
}
if((Get-ItemProperty -Path HKLM:\SOFTWARE\FSLogix\Profiles -Name VHDLocations -ErrorAction SilentlyContinue) -eq $null )
{
    New-ItemProperty -Path HKLM:\SOFTWARE\FSLogix\Profiles -Name VHDLocations -PropertyType MultiString -Value @($uncPath)
}
else {
    Set-ItemProperty -Path HKLM:\SOFTWARE\FSLogix\Profiles -Name VHDLocations -Value @($uncPath) -Force -Confirm:$false
}