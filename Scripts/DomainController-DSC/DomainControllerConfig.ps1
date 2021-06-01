configuration DomainControllerConfig
{
    param
    (    
        [Parameter(mandatory = $true)]
        [string]$username,
        [Parameter(Mandatory = $true)]
        [string]$password,
        [Parameter(mandatory = $true)]
        [string]$domain,
        [Parameter(mandatory = $false)]
        [string]$site = "Default-First-Site-Name"
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
                
                $securepassword = ConvertTo-SecureString -String $using:password -AsPlainText -Force
                $domainCredential = New-Object System.Management.Automation.PSCredential ($using:username, $securepassword)
                New-Item -Path "N:\NTDS" -ItemType Directory;
                New-Item -Path "S:\SYSVOL" -ItemType Directory;    
                
                Install-ADDSDomainController -SkipPreChecks -DomainName $using:domain -SafeModeAdministratorPassword $securepassword -SiteName $using:site -Credential $domainCredential -DatabasePath "N:\NTDS" -SysvolPath "S:\SYSVOL" -Confirm:$false -Force;
            }
            TestScript = {
                return ((Get-Item -Path S:\SYSVOL -ErrorAction SilentlyContinue) -ne $null)
            }
        } 
    }
}