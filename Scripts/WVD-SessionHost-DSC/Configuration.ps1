configuration AddSessionHost
{
    param
    (    
        [Parameter(mandatory = $true)]
        [string]$HostPoolName,

        [Parameter(mandatory = $true)]
        [string]$scriptUrl,

        [Parameter(Mandatory = $true)]
        [string]$uncPath,

        [Parameter(Mandatory = $true)]
        [string]$appId,

        [Parameter(Mandatory = $true)]
        [string]$tenantId,

        [Parameter(Mandatory = $true)]
        [string]$keyVaultId,

        [Parameter(Mandatory = $true)]
        [string]$secretName,

        [Parameter(Mandatory = $true)]
        [string]$hostPoolResourceId
    )

    $rdshIsServer = $true
    $ScriptPath = [system.io.path]::GetDirectoryName($PSCommandPath)
    $tokenScript = Invoke-WebRequest "$($scriptUrl)/WVD-HostPool-RegistrationKey.ps1" -UseBasicParsing
    $tokenBlock = [Scriptblock]::Create($tokenScript.Content)
    $RegistrationInfoToken = & "$($scriptUrl)/WVD-HostPool-RegistrationKey.ps1 -appId $appId -tenantId $tenantId -keyVaultName $keyVaultName -secretName $secretName -hostPoolResourceId $hostPoolResourceId"

    Script GetHostPoolToken {
        GetScript = {
            return @{'Result' = ''}
        }
        SetScript = {
            & "$using:scriptUrl\WVD-HostPool-RegistrationKey.ps1"
        }
        TestScript = {
            return (Test-path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\FSLogix\Profiles\VHDLocations")
        }
    }

    $OSVersionInfo = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
    
    if ($OSVersionInfo -ne $null)
    {
        if ($OSVersionInfo.InstallationType -ne $null)
        {
            $rdshIsServer=@{$true = $true; $false = $false}[$OSVersionInfo.InstallationType -eq "Server"]
        }
    }

    Node localhost
    {
        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true
            ConfigurationMode = "ApplyOnly"
        }

        if ($rdshIsServer)
        {
            "$(get-date) - rdshIsServer = true: $rdshIsServer" | out-file c:\windows\temp\rdshIsServerResult.txt -Append
            WindowsFeature RDS-RD-Server
            {
                Ensure = "Present"
                Name = "RDS-RD-Server"
            }

            Script ExecuteRdAgentInstallServer
            {
                DependsOn = "[WindowsFeature]RDS-RD-Server"
                GetScript = {
                    return @{'Result' = ''}
                }
                SetScript = {
                    & "$using:ScriptPath\Script-AddRdshServer.ps1" -HostPoolName $using:HostPoolName -RegistrationInfoToken $using:RegistrationInfoToken
                }
                TestScript = {
                    return (Test-path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\RDInfraAgent")
                }
            }
        }
        else
        {
            "$(get-date) - rdshIsServer = false: $rdshIsServer" | out-file c:\windows\temp\rdshIsServerResult.txt -Append
            Script ExecuteRdAgentInstallClient
            {
                GetScript = {
                    return @{'Result' = ''}
                }
                SetScript = {
                    & "$using:ScriptPath\Script-AddRdshServer.ps1" -HostPoolName $using:HostPoolName -RegistrationInfoToken $using:RegistrationInfoToken
                }
                TestScript = {
                    return (Test-path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\RDInfraAgent")
                }
            }
        }

        Script ExecutFSLogixInstall
        {
            GetScript = {
                return @{'Result' = ''}
            }
            SetScript = {
                & "$using:ScriptPath\FSLogixInstall.ps1" -uncPath $using:uncPath
            }
            TestScript = {
                return (Test-path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\FSLogix\Profiles\VHDLocations")
            }
        }
    }
}