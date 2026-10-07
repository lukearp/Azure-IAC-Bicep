# Remove Unknown Azure RBAC Assignments

`Remove-Unknown-RBACAssignments.ps1` finds Azure role assignments whose principal
object IDs no longer resolve to directory objects in Microsoft Entra ID. It can
optionally remove assignments only after Microsoft Graph confirms that the principal
is absent.

The script does not determine whether an assignment is orphaned from Azure's
`ObjectType` value. Deleted principals can still be reported as a user or service
principal even when the Azure portal displays them as **Unknown**. Instead, the script
checks each distinct principal ID with Microsoft Graph's
`directoryObjects/getByIds` endpoint.

## Safety behavior

- By default, the script makes no changes. It scans the selected subscription(s) and
  writes a CSV report for confirmed orphaned assignments.
- Add `-Remove` to request removal of assignments confirmed absent by Microsoft Graph.
  Removal uses PowerShell's `ShouldProcess` behavior, so it prompts for confirmation by
  default.
- If Microsoft Graph cannot verify principals (for example, because the signed-in
  identity lacks permission), the script records the affected assignments as
  `NotVerified` and `Skipped`. It does **not** remove them.
- Use `-WhatIf` with `-Remove` to preview the removal path without changing Azure.
- The script restores the Azure context that was active when it started.

Review the report and confirm the target subscription, role, principal ID, and scope
before allowing removals. Removing a role assignment can affect access immediately.

## Requirements and permissions

The machine running the script needs:

- PowerShell with the `Az.Accounts` and `Az.Resources` modules.
- An authenticated Azure context. The identity must be able to enumerate role
  assignments in the selected subscription(s), which requires
  `Microsoft.Authorization/roleAssignments/read` at the applicable scopes.
- Permission for the signed-in identity to read directory objects through Microsoft
  Graph. For resolving arbitrary directory object types, the tenant may require the
  Microsoft Graph `Directory.Read.All` permission and admin consent.
- To use `-Remove`, `Microsoft.Authorization/roleAssignments/delete` at each assignment
  scope being cleaned up. The exact Azure role that grants the necessary actions
  depends on your organization's role and scope setup.

Grant only the permissions needed for the intended run. A subscription-wide scan
requires access to every subscription selected, and removal requires delete access at
the scopes of assignments being removed.

## Setup

Install the required modules if they are not already installed:

```powershell
Install-Module Az.Accounts, Az.Resources -Scope CurrentUser
```

Sign in with an identity that has the required Azure and Microsoft Graph permissions:

```powershell
Connect-AzAccount
Get-AzContext
```

If the identity has access to multiple tenants, sign in to the tenant containing the
subscriptions you intend to inspect. Check the displayed context before running a
removal.

## Usage

Run these examples from the script's directory, or replace the script name with its
full path.

### Report the current subscription (default)

```powershell
.\Remove-Unknown-RBACAssignments.ps1
```

The script inspects the subscription in the current Azure context. It does not remove
assignments.

### Report one or more specified subscriptions

```powershell
.\Remove-Unknown-RBACAssignments.ps1 -SubscriptionId '00000000-0000-0000-0000-000000000000'
```

Multiple subscription IDs can be passed as an array:

```powershell
.\Remove-Unknown-RBACAssignments.ps1 -SubscriptionId @(
    '00000000-0000-0000-0000-000000000000',
    '11111111-1111-1111-1111-111111111111'
)
```

### Report all accessible subscriptions

```powershell
.\Remove-Unknown-RBACAssignments.ps1 -AllSubscriptions
```

Only subscriptions returned by `Get-AzSubscription` for the signed-in identity are
included.

### Choose the report file

```powershell
.\Remove-Unknown-RBACAssignments.ps1 `
    -SubscriptionId '00000000-0000-0000-0000-000000000000' `
    -ReportPath '.\reports\unknown-rbac.csv'
```

If `-ReportPath` is omitted, the script writes a timestamped file named
`Unknown-RBACAssignments-yyyyMMdd-HHmmss.csv` in the current working directory. A
missing parent directory is created. If the chosen path already exists, its contents
are overwritten.

### Preview removals

```powershell
.\Remove-Unknown-RBACAssignments.ps1 `
    -SubscriptionId '00000000-0000-0000-0000-000000000000' `
    -Remove `
    -WhatIf
```

`-WhatIf` shows the operations that would be attempted without deleting assignments.
It does not bypass the principal verification requirement.

### Remove confirmed orphaned assignments

```powershell
.\Remove-Unknown-RBACAssignments.ps1 `
    -SubscriptionId '00000000-0000-0000-0000-000000000000' `
    -Remove
```

The script prompts before each removal. To suppress those prompts, pass
`-Confirm:$false` only when the target and impact have been reviewed:

```powershell
.\Remove-Unknown-RBACAssignments.ps1 `
    -AllSubscriptions `
    -Remove `
    -Confirm:$false
```

With this option, confirmed orphaned assignments in all accessible subscriptions are
removed without an individual confirmation prompt. Use `-WhatIf` first when validating
a new target set.

## Report fields

When there are report entries, the script writes a CSV with these columns:

| Column | Meaning |
| --- | --- |
| `SubscriptionName` | Name of the subscription containing the assignment. |
| `SubscriptionId` | Subscription ID. |
| `TenantId` | Tenant ID associated with the subscription. |
| `PrincipalId` | Object ID of the principal on the role assignment. |
| `ReportedType` | Object type returned for the assignment by Azure; it is informational and is not used to decide whether the principal exists. |
| `RoleDefinitionName` | Name of the assigned Azure role. |
| `Scope` | Scope at which the role is assigned. |
| `RoleAssignmentId` | ID of the role assignment. |
| `GraphVerification` | `NotFound` if Graph successfully checked the IDs and did not return this principal; `NotVerified` if the check failed. |
| `Action` | `WouldRemove` for a confirmed orphan in report-only mode; `Removed` after successful deletion; `RemoveFailed` if deletion failed; `Skipped` if Graph verification failed; or `RemovalDeclined` if `ShouldProcess` did not approve the removal (including `-WhatIf`). |
| `Error` | Verification or removal error details, when applicable. |

No CSV is created when there are no report entries. In particular, if no confirmed
orphaned assignments are found, the script reports that fact and exits without creating
a file. If Graph verification fails, affected assignments are included in the report
as skipped so the verification problem is visible.

## Troubleshooting

### No Azure context found

Run `Connect-AzAccount`, select the intended subscription with `Set-AzContext` if
needed, then rerun the script.

### Graph verification failed; assignments were skipped

Check that the signed-in identity can read the relevant directory objects through
Microsoft Graph, and ask a tenant administrator to grant or consent to the required
permission if necessary. Do not treat `NotVerified` as proof that a principal is
deleted; the script deliberately does not remove those assignments.

### A subscription or role assignment could not be read or removed

Confirm that the identity has the required Azure permissions at the subscription or
assignment scope. Check the warning and the report's `Error` field for details.
