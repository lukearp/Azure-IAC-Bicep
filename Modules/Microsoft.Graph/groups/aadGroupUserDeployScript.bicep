param GroupName string
param managedIdentityId string
param location string
param Users array = []

/*module adGroup '../../Microsoft.Resources/deploymentScripts/deploymentScripts-powershell-scriptblock.bicep' = { 
   name: 'AD-Group-And-Users'
   params: { 
      managedIdentityId: managedIdentityId
      name: 'AD-Group-And-Users' 
      location: location
      psScriptContent: 'Connect-AzAccount -Identity;$group = Get-AzAdGroup -DisplayNameStartsWith "$($args[0])";if($null -eq $group){$group = New-AzADGroup -DisplayName "$($args[0])" -MailNickname "$($args[0])" -SecurityEnabled;};$length = 12;$randomString = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count $length | ForEach-Object {[char]$_});foreach($user in $args[1]){$existing = Get-AzADUser -UserPrincipalName "$($user)";if($existing -eq $null){try{New-AzADUser -DisplayName "$($user.split("@")[0])" -UserPrincipalName "$($user)" -MailNickname "$($user.split("@")[0])" -Password $(ConvertTo-SecureString -String $randomString -AsPlainText -Force)}catch{sleep 5;New-AzADUser -DisplayName "$($user.split("@")[0])" -UserPrincipalName "$($user)" -MailNickname "$($user.split("@")[0])" -Password $(ConvertTo-SecureString -String $randomString -AsPlainText -Force);}};};foreach($user in $args[1]){$members = Get-AzADGroupMember -GroupObjectId $group.id;if($members.UserPrincipalName -contains $user){Write-Output "$($user) in Group";}else {Add-AzADGroupMember -MemberUserPrincipalName "$($user)" -TargetGroupObjectId $group.Id;};};$DeploymentScriptOutputs = @{};$DeploymentScriptOutputs[\'userPassword\'] = $randomString;$DeploymentScriptOutputs[\'groupId\'] = $group.id;'
      arguments: '${GroupName} ${Users}'
      azPowershellVersion: '10.0' 
   }  
}*/

var UsersString = [for user in Users: '${user}' ]

module adGroup '../../Microsoft.Resources/deploymentScripts/deploymentScripts-powershell-scriptblock.bicep' = { 
   name: 'AD-Group-And-Users'
   params: {
      managedIdentityId: managedIdentityId
      name: 'AD-Group-And-Users'
      location: location
      psScriptContent: '''
Connect-AzAccount -Identity;
$users = $args[1..($args.Length - 1)]
$userDetails = @{
     accountEnabled = $true
     displayName = ""
     mailNickname = ""
     userPrincipalName = ""
     passwordProfile = @{
         forceChangePasswordNextSignIn = $true
         password = ""
     }
};
$group = Get-AzAdGroup -DisplayNameStartsWith "$($args[0])";
if ($null -eq $group) {
    $group = New-AzADGroup -DisplayName "$($args[0])" -MailNickname "$($args[0])" -SecurityEnabled;
}; 
$length = 12; 
$randomString = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count $length | ForEach-Object { [char]$_ }); 
foreach ($user in $users) { 
    Write-Output $user
    $existing = Get-AzADUser -UserPrincipalName "$($user)"; 
    if ($existing -eq $null) { 
        try { 
            $userDetails.displayName = $($user.split("@")[0]);
            $userDetails.userPrincipalName = $user;
            $userDetails.mailNickname = $($user.split("@")[0]);
            $userDetails.passwordProfile.password = $randomString
            $userDetailJson = $userDetails | ConvertTo-Json -Depth 10;
            $output = Invoke-AzRestMethod -Method Post -Uri "https://graph.microsoft.com/v1.0/users" -Payload $userDetailJson;
            $count = 0
            if($output.StatusCode -ne 201)
            {
            do {
                sleep 5;
                Write-Output "Failed to create $($user), trying again"
                $output = Invoke-AzRestMethod -Method Post -Uri "https://graph.microsoft.com/v1.0/users" -Payload $userDetailJson;
                $count++
            }while($output.StatusCode -ne 201 -or $count -eq 5)              
            }                      
        }
        catch {
        } 
    }; 
}; 
sleep 15;
foreach ($user in $users) { 
    Write-Output $user
    $members = Get-AzADGroupMember -GroupObjectId $group.id; 
    if ($members.UserPrincipalName -contains $user) { 
        Write-Output "$($user) in Group"; 
    }
    else { 
        Add-AzADGroupMember -MemberUserPrincipalName "$($user)" -TargetGroupObjectId $group.Id; 
    }; 
}; 
$DeploymentScriptOutputs = @{}; 
$DeploymentScriptOutputs['userPassword'] = $randomString; 
$DeploymentScriptOutputs['groupId'] = $group.id;
'''
      arguments: '${GroupName} ${join(UsersString, ' ')}'
      azPowershellVersion: '10.0' 
   }
}

output password string = adGroup.outputs.results['userPassword']
output groupId string = adGroup.outputs.results['groupId']
