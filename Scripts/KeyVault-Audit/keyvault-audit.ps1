$csvPath = ".\keyvault.csv"
$graphQuery = "resources | where type == `"microsoft.keyvault/vaults`" | project name, ArmRBAC=properties[`"enableRbacAuthorization`"],properties[`"accessPolicies`"],subscription=split(id,`"/`")[2],resourceGroup,id"

$keyVaults = Search-AzGraph -Query $graphQuery
$reports = @()
foreach($vault in $keyVaults)
{
    Select-AzSubscription -Subscription $vault.subscription
    $vaultObject = Get-AzKeyVault -VaultName $vault.name -ResourceGroupName $vault.resourceGroup
    $roleAssignments = @()
    if($vaultObject.EnableRbacAuthorization -eq $true)
    {
        $assignedRBACRoles = $null
        $assignedRBACRoles = Get-AzRoleAssignment -Scope $vaultObject.ResourceId | ?{$_.RoleDefinitionName -like "Key Vault *"} | Select-Object RoleDefinitionName,ObjectType,ObjectId
        foreach($role in $assignedRBACRoles)
        {
            $roleAssignments += New-Object -TypeName psobject -Property @{
                ObjectId = $role.ObjectId
                UserName = $role.ObjectType -eq "User" ? (Get-AzAdUser -ObjectId $role.ObjectId).UserPrincipalName : ""
                Type = $role.ObjectType
                RoleDefinitionName = $role.RoleDefinitionName
            }
        }        
    }
    else {
        foreach($policy in $vaultObject.AccessPolicies)
        {
            $roleAssignments += New-Object -TypeName psobject -Property @{
                ObjectId = $policy.ObjectId -eq $null ? $policy.ApplicationId : $policy.ObjectId
                UserName = $policy.ObjectId -eq $null ? (Get-AzAdUser -ObjectId $role.ObjectId).UserPrincipalName : ""
                DisplayName = $policy.DisplayName
                KeyPermission = $policy.PermissionsToKeys -join ";"
                SecretPermissions = $policy.PermissionsToSecrets -join ";"
                CertificatePermissions = $policy.PermissionsToCertificates -join ";"
            }
        }
    }
    $reports += New-Object -TypeName psobject -Property @{
        name = $vaultObject.VaultName
        resourceGroup = $vault.resourceGroup
        subscription = $vault.subscription
        AzureRBACEnabled = $vaultObject.EnableRbacAuthorization
        PublicAccessEnabled = $vaultObject.PublicNetworkAccess
        NetworkRules = ConvertTo-Json -inputobject $vaultObject.NetworkAcls -depth 10 -Compress
        roleAssignments = ConvertTo-Json -inputobject $roleAssignments -Depth 10 -Compress
    }
}
Add-Content -Path $csvPath -Value "Name,Resource Group,Subscription,Azure RBAC Enabled, Network Rules, Role Assignments"

foreach($report in $reports)
{
    Add-Content -Path $csvPath -Value "$($report.name),$($report.resourceGroup),$($report.subscription),$($report.AzureRBACEnabled),$($report.PublicAccessEnabled),$($report.NetworkRules),$($report.roleAssignments)"
}