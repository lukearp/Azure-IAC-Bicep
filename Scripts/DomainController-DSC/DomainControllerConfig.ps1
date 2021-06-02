configuration DomainControllerConfig
{
    param
    (    
        [Parameter(mandatory = $true)]
        [System.Management.Automation.PSCredential]$creds,
        [Parameter(mandatory = $true)]
        [string]$domain,
        [Parameter(mandatory = $true)]
        [string]$newForest,
        [Parameter(mandatory = $false)]
        [string]$site
    )
    
    Import-DscResource -ModuleName PsDesiredStateConfiguration 
    node localhost
    {
        WindowsFeature ADDSInstall {
            Ensure               = 'Present'
            Name                 = 'AD-Domain-Services'
            IncludeAllSubFeature = $true
        }
    
        Script SetupDisk {
            DependsOn = "[WindowsFeature]ADDSInstall"
            GetScript  = {
                return @{'Result' = '' }
            }
            SetScript  = {
                $disk = Get-Disk -Number 2
                New-Volume -Disk $disk -FileSystem NTFS -DriveLetter N -FriendlyName "NTDS"
                $disk = Get-Disk -Number 3
                New-Volume -Disk $disk -FileSystem NTFS -DriveLetter S -FriendlyName "SYSVOL"
            }
            TestScript = {
                return ((Get-Volume -DriveLetter N -ErrorAction SilentlyContinue) -ne $null)
            }
        }
    
        Script DCPromo {
            GetScript  = {
                return @{'Result' = '' }
            }
            SetScript  = {
                
                #$securepassword = ConvertTo-SecureString -String $using:password -AsPlainText -Force
                $domainCredential = $using:creds
                if((Get-Item -Path "N:\NTDS" -ErrorAction SilentlyContinue) -eq $null)
                {
                    New-Item -Path "N:\NTDS" -ItemType Directory;
                }
                if((Get-Item -Path "S:\SYSVOL" -ErrorAction SilentlyContinue) -eq $null)
                {
                    New-Item -Path "S:\SYSVOL" -ItemType Directory;
                }
                $stringOutput = $using:creds.UserName + " " + $using:domain + " " + $using:site + " " + $using:creds.Password 
                Add-Content -Path "C:\users.txt" -Value $stringOutput
                if($using:newForest -ne $true)
                {
                    Install-ADDSDomainController -SkipPreChecks -DomainName $using:domain -SafeModeAdministratorPassword $domainCredential.Password -SiteName $using:site -Credential $domainCredential -DatabasePath "N:\NTDS" -SysvolPath "S:\SYSVOL" -LogPath "N:\NTDS"  -Confirm:$false -Force;
                }
                else {
                    Install-ADDSForest -SkipPreChecks -DomainName $using:domain -SafeModeAdministratorPassword $domainCredential.Password -DatabasePath "N:\NTDS" -SysvolPath "S:\SYSVOL" -LogPath "N:\NTDS" -NoRebootOnCompletion:$false -Confirm:$false -Force;
                }
            }
            TestScript = {
                return ((Get-Item -Path S:\SYSVOL\sysvol -ErrorAction SilentlyContinue) -ne $null)
            }
        } 
    }
}