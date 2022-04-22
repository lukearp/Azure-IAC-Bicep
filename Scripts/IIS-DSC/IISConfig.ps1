configuration IISConfig
{  
    Import-DscResource -ModuleName PsDesiredStateConfiguration 
    node localhost
    {
        WindowsFeature IISInstall {
            Ensure               = 'Present'
            Name                 = 'Web-Server'
            IncludeAllSubFeature = $true
        }
    }
}