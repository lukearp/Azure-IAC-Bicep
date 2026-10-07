#Requires -Modules Az.Accounts, Az.Resources

<#
.SYNOPSIS
    Finds and optionally removes Azure RBAC assignments whose principals no longer exist.

.DESCRIPTION
    Enumerates role assignments and verifies their principal IDs with Microsoft Graph.
    An assignment is eligible for removal only when Graph can be queried successfully and
    does not return the directory object. This does not rely on the Azure PowerShell
    ObjectType value because deleted principals can still be reported as User or
    ServicePrincipal while the Azure portal displays them as "Unknown".

    The script runs against the current subscription by default and only writes a report.
    Use -Remove to delete verified orphaned assignments. Unknown assignments caused by
    insufficient Microsoft Graph permissions are not removed.

    The signed-in identity needs permission to read directory objects in Microsoft Graph
    and Microsoft.Authorization/roleAssignments/delete at each assignment scope.

.PARAMETER SubscriptionId
    One or more subscription IDs to inspect.

.PARAMETER AllSubscriptions
    Inspects every subscription available to the signed-in identity.

.PARAMETER Remove
    Removes assignments whose principals are confirmed absent. Without this switch, the
    script only reports what it would remove.

.PARAMETER ReportPath
    CSV path for the audit report.

.EXAMPLE
    .\Remove-Unknown-RBACAssignments.ps1

    Reports orphaned assignments in the current subscription without changing Azure.

.EXAMPLE
    .\Remove-Unknown-RBACAssignments.ps1 -SubscriptionId '<subscription-id>' -Remove

    Verifies orphaned assignments and prompts before removing each one.

.EXAMPLE
    .\Remove-Unknown-RBACAssignments.ps1 -AllSubscriptions -Remove -Confirm:$false

    Removes verified orphaned assignments from all accessible subscriptions without
    individual confirmation prompts.
#>
[CmdletBinding(DefaultParameterSetName = 'Current', SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory = $true, ParameterSetName = 'BySubscription')]
    [ValidateNotNullOrEmpty()]
    [string[]]$SubscriptionId,

    [Parameter(Mandatory = $true, ParameterSetName = 'All')]
    [switch]$AllSubscriptions,

    [switch]$Remove,

    [ValidateNotNullOrEmpty()]
    [string]$ReportPath = (Join-Path -Path $PWD -ChildPath "Unknown-RBACAssignments-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv")
)

$ErrorActionPreference = 'Stop'
$originalContext = Get-AzContext

if (-not $originalContext) {
    throw 'No Azure context found. Run Connect-AzAccount before running this script.'
}

switch ($PSCmdlet.ParameterSetName) {
    'BySubscription' {
        $subscriptions = foreach ($id in $SubscriptionId) {
            Get-AzSubscription -SubscriptionId $id
        }
    }
    'All' {
        $subscriptions = Get-AzSubscription
    }
    default {
        $subscriptions = Get-AzSubscription -SubscriptionId $originalContext.Subscription.Id
    }
}

$subscriptions = @($subscriptions | Sort-Object -Property Id -Unique)
$report = [System.Collections.Generic.List[object]]::new()
$processedAssignmentIds = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

try {
    foreach ($subscription in $subscriptions) {
        Write-Host "Inspecting subscription '$($subscription.Name)' ($($subscription.Id))"
        $context = Set-AzContext -SubscriptionId $subscription.Id -TenantId $subscription.TenantId

        $assignments = @(
            Get-AzRoleAssignment |
                Where-Object {
                    -not [string]::IsNullOrWhiteSpace($_.ObjectId) -and
                    -not [string]::IsNullOrWhiteSpace($_.RoleAssignmentId) -and
                    $processedAssignmentIds.Add([string]$_.RoleAssignmentId)
                }
        )

        if ($assignments.Count -eq 0) {
            Write-Host 'No new role assignments found.'
            continue
        }

        $principalIds = @($assignments.ObjectId | Sort-Object -Unique)
        $existingPrincipalIds = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
        $verificationError = $null

        try {
            for ($offset = 0; $offset -lt $principalIds.Count; $offset += 1000) {
                $lastIndex = [Math]::Min($offset + 999, $principalIds.Count - 1)
                $batchIds = @($principalIds[$offset..$lastIndex])
                $payload = @{ ids = $batchIds } | ConvertTo-Json -Depth 3
                $response = Invoke-AzRestMethod `
                    -Method POST `
                    -Uri 'https://graph.microsoft.com/v1.0/directoryObjects/getByIds' `
                    -Payload $payload `
                    -DefaultProfile $context

                if ([int]$response.StatusCode -ne 200) {
                    throw "Microsoft Graph returned HTTP $([int]$response.StatusCode)."
                }

                $content = $response.Content | ConvertFrom-Json
                foreach ($directoryObject in $content.value) {
                    [void]$existingPrincipalIds.Add([string]$directoryObject.id)
                }
            }
        }
        catch {
            $verificationError = $_.Exception.Message
            Write-Warning "Could not verify principals in tenant '$($subscription.TenantId)': $verificationError No assignments will be removed from this subscription."
        }

        $orphanedAssignments = if ($verificationError) {
            $assignments
        }
        else {
            @($assignments | Where-Object { -not $existingPrincipalIds.Contains([string]$_.ObjectId) })
        }

        if ($orphanedAssignments.Count -eq 0) {
            Write-Host 'No verified orphaned role assignments found.'
            continue
        }

        foreach ($assignment in $orphanedAssignments) {
            $graphVerification = if ($verificationError) { 'NotVerified' } else { 'NotFound' }
            $action = if ($verificationError) { 'Skipped' } else { 'WouldRemove' }
            $errorMessage = $verificationError

            if (-not $verificationError -and $Remove) {
                $target = "$($assignment.RoleDefinitionName) assignment for principal $($assignment.ObjectId) at $($assignment.Scope)"
                if ($PSCmdlet.ShouldProcess($target, 'Remove Azure RBAC role assignment')) {
                    try {
                        Remove-AzRoleAssignment -ObjectId $assignment.ObjectId -RoleDefinitionName $assignment.RoleDefinitionName -Scope $assignment.Scope -Confirm:$false
                        $action = 'Removed'
                    }
                    catch {
                        $action = 'RemoveFailed'
                        $errorMessage = $_.Exception.Message
                        Write-Warning "Failed to remove role assignment '$($assignment.RoleAssignmentId)': $errorMessage"
                    }
                }
                else {
                    $action = 'RemovalDeclined'
                }
            }

            $report.Add([pscustomobject]@{
                    SubscriptionName  = $subscription.Name
                    SubscriptionId    = $subscription.Id
                    TenantId          = $subscription.TenantId
                    PrincipalId       = $assignment.ObjectId
                    ReportedType      = $assignment.ObjectType
                    RoleDefinitionName = $assignment.RoleDefinitionName
                    Scope             = $assignment.Scope
                    RoleAssignmentId  = $assignment.RoleAssignmentId
                    GraphVerification = $graphVerification
                    Action            = $action
                    Error             = $errorMessage
                })
        }
    }
}
finally {
    Set-AzContext -Context $originalContext | Out-Null
}

if ($report.Count -gt 0) {
    $reportDirectory = Split-Path -Path $ReportPath -Parent
    if ($reportDirectory -and -not (Test-Path -LiteralPath $reportDirectory)) {
        New-Item -Path $reportDirectory -ItemType Directory -Force | Out-Null
    }

    $report | Export-Csv -Path $ReportPath -NoTypeInformation
    Write-Host "Report written to '$ReportPath'."
    $report
}
else {
    Write-Host 'No orphaned role assignments were found; no report was created.'
}