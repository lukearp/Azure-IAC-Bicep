# Bulk Add WAF IP Block Rule

`WAF-IPBlock.ps1` adds or replaces a custom WAF rule named `BlockMaliciousIP` on every supported Azure WAF policy that the signed-in identity can discover in the tenant. The rule is assigned priority **1**, uses the `IPMatch` operator against the requester's `RemoteAddr`, and blocks requests from the configured IP addresses or CIDR ranges.

> [!WARNING]
> This script updates live WAF policies in place. It has no `-WhatIf`, confirmation prompt, automatic backup, or rollback. Review the target policies and IP list before running it, and export policy configurations first.

## Supported policy types

The script discovers these resource types through Azure Resource Graph:

| WAF policy type | Azure resource type | Rule representation used by the script |
| --- | --- | --- |
| Application Gateway WAF policy | `Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies` | Application Gateway `customRules` |
| Azure Front Door WAF policy | `Microsoft.Network/FrontDoorWebApplicationFirewallPolicies` | Front Door `customRules.rules` |

All accessible policies of both types are included. Discovery is tenant-scoped, so this can affect policies in multiple subscriptions, management groups, and resource groups where the current identity has access.

## What the script does

For every discovered policy, `WAF-IPBlock.ps1`:

1. Retrieves the current policy by using Azure Resource Manager REST APIs.
2. Creates a `BlockMaliciousIP` match rule with priority `1` and `Block` action.
3. Matches `RemoteAddr` against the configured IPv4, IPv6, and/or CIDR values.
4. Removes any existing rules named `BlockMaliciousIP` (case-insensitive), so the script can be safely re-run without creating duplicate rules.
5. Reorders the remaining custom rules to give each rule a unique priority from `2` through `100` while preserving their existing priority where possible.
6. Sends an in-place `PUT` update containing only writable policy properties (`customRules`, `policySettings`, and `managedRules`) plus the resource location, tags, and SKU when present.
7. Continues to the next policy if an individual update fails, writing a warning for that policy.

### Rule created for Application Gateway

The Application Gateway policy receives a rule equivalent to:

| Property | Value |
| --- | --- |
| Name | `BlockMaliciousIP` |
| Priority | `1` |
| State | `Enabled` |
| Rule type | `MatchRule` |
| Action | `Block` |
| Match variable | `RemoteAddr` |
| Operator | `IPMatch` |
| Negation | `false` |
| Match values | Configured addresses/ranges |

### Rule created for Front Door

The Front Door policy receives the same effective IP-match/block behavior. Its schema also includes `enabledState: Enabled`, an empty transform list, and the required rate-limit fields with a duration of one minute and a threshold of `0`. These rate-limit values do not make this a rate-limit rule; the rule type remains `MatchRule`.

## Prerequisites

Before running the script, ensure the following:

- PowerShell 7 or Windows PowerShell with the Az PowerShell modules installed.
- `Az.Accounts` for `Connect-AzAccount` and `Invoke-AzRestMethod`.
- `Az.ResourceGraph` for `Search-AzGraph`.
- An authenticated Azure session. Use an identity appropriate for the policies that should be changed.
- Permission to query resources at tenant scope and to update every target WAF policy. `Network Contributor` at each WAF policy scope (or an appropriate broader scope) is typically required for the updates.
- No existing custom rule whose priority must remain fixed at `100` if other rules need to be shifted beyond it. Azure custom-rule priorities are limited to `1` through `100`.

Check the installed modules and sign in:

```powershell
Get-Module -ListAvailable Az.Accounts, Az.ResourceGraph
Connect-AzAccount
```

If the required modules are absent, install the Az module according to the organization's approved PowerShell module process. The script uses the currently authenticated identity and does not accept credentials as arguments.

## Configure the addresses to block

The IP list is currently defined in the script rather than exposed as a parameter. Edit the `$defaultIpsToBlock` array near the top of [WAF-IPBlock.ps1](WAF-IPBlock.ps1) before running:

```powershell
$defaultIpsToBlock = @(
	'203.0.113.10',
	'198.51.100.0/24',
	'2001:db8:1234::/48'
)
```

Valid values are:

- An IPv4 address, such as `203.0.113.10`
- An IPv6 address, such as `2001:db8::10`
- An IPv4 CIDR range with a prefix from `0` to `32`, such as `198.51.100.0/24`
- An IPv6 CIDR range with a prefix from `0` to `128`, such as `2001:db8:1234::/48`

The script sorts and de-duplicates the configured values before updating policies. It stops before any updates if the list is empty or an address/range is invalid.

> [!IMPORTANT]
> Do not block addresses used by trusted administrators, health probes, reverse proxies, VPN/NAT gateways, or Azure services required by the application. Confirm the value observed by WAF as `RemoteAddr`; it may be a proxy address depending on the traffic path.

## Recommended safe workflow

1. **Identify the intended scope.** The script does not support limiting execution to one subscription, resource group, policy, or policy type. Because it uses `-UseTenantScope`, ensure the signed-in identity cannot unintentionally modify unrelated policies.
2. **Back up existing policies.** Export or record each policy's current custom rules and policy settings. Keep the exported data outside this folder or under source control with appropriate secret handling.
3. **Validate the address list.** Check whether each entry is an individual host or a CIDR range and verify that it will not block legitimate traffic.
4. **Test on a non-production policy first.** Use an account whose access is limited to the test scope where possible.
5. **Run the script.** Execute it from this directory or provide its full path.
6. **Verify every updated policy.** Confirm that `BlockMaliciousIP` is priority `1`, contains the intended values, and that all other custom rules still have the intended order.
7. **Monitor WAF logs and application availability.** Watch for unexpected blocks immediately after the change.

## Run the script

From this folder, run:

```powershell
.\WAF-IPBlock.ps1
```

To make the Azure account context explicit before execution:

```powershell
Connect-AzAccount
.\WAF-IPBlock.ps1
```

The script writes warnings when a particular policy cannot be updated. Successful policy updates are accumulated internally, but the summary response section is currently commented out in [WAF-IPBlock.ps1](WAF-IPBlock.ps1). Therefore, a successful run can complete with no console output. Check the Azure portal, Azure Activity Log, or policy configuration directly after execution.

## Verify the result

In the Azure portal, open each affected WAF policy and inspect **Custom rules**. Confirm the following:

- `BlockMaliciousIP` exists and is enabled.
- Its priority is `1`.
- Its action is **Block**.
- Its match condition is **IP address** / `IPMatch` against `RemoteAddr`.
- The IP addresses and CIDR ranges exactly match the configured list.
- Other custom rules have unique priorities and still reflect the required processing order.

You can also query the target policy configuration through Azure Resource Manager or use the Activity Log to confirm the policy write operation.

## Priority and idempotency behavior

Azure requires unique custom-rule priorities in the range $1$–$100$. To reserve priority `1` for the blocking rule, the script removes pre-existing copies of the same rule, sorts the other rules by their existing priority and name, and assigns them non-conflicting priorities starting at `2`.

This makes the `BlockMaliciousIP` rule idempotent: running the script again replaces the previous copy instead of adding another one. However, it can also change the priorities of **other** custom rules. Treat the existing priority order as part of the policy's behavior and review it after every run.

The update fails for a policy if a remaining rule would need a priority above `100`. The script records that policy as failed and continues attempting the others.

## Error handling and limitations

| Scenario | Script behavior |
| --- | --- |
| Invalid IP/CIDR or an empty list | Stops before policy updates and writes a warning. |
| Unsupported policy resource type | Throws for that policy; the outer loop records a warning and continues. |
| Insufficient access, lock, API failure, or policy validation error | Writes a warning for that policy and continues to the next policy. |
| Conflicting/overflowing priorities | Fails that policy when a priority greater than `100` would be required. |
| No matching WAF policies found | Completes without updates. |

Additional limitations:

- There is no built-in `-WhatIf`, dry run, confirmation, scope filter, backup, rollback, or change report output.
- The hard-coded rule name is `BlockMaliciousIP`, and the new rule always uses priority `1` and a block action.
- The script updates Application Gateway and Front Door WAF **policies**, not WAF settings configured directly on an individual Application Gateway.
- A failed policy update does not roll back policies that were updated earlier in the run.
- The REST API versions are fixed in the script: `2024-05-01` for Application Gateway WAF policies and `2022-05-01` for Front Door WAF policies.

## Rollback

Use the policy backup created before execution to restore the prior custom rules and their priorities. If a full backup is not available, manually remove `BlockMaliciousIP` from the affected policy and restore the original priority of every remaining custom rule. Review the complete policy configuration before saving it.

Do not assume deleting only the new rule returns the policy to its original state: the script may have re-prioritized other rules.

## Security and operational guidance

- Treat broad CIDR ranges as high impact; use the narrowest range that satisfies the incident response need.
- Change-control, peer review, and an emergency rollback plan are recommended for production policies.
- Prefer a least-privileged identity and a constrained test scope when validating changes.
- Record the source of every blocked IP, the approval, the deployment time, and the planned removal date.
- Review WAF logs after deployment and remove temporary incident-response blocks once they are no longer needed.
