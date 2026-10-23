# Front Door WAF Custom Rules

Enforces assignment-supplied custom rules on **all Azure Front Door WAF policies in the assignment scope**, including newly created policies. Managed names end in `PolicyEnforced`; unrelated rules are preserved.

## Files

- [frontdoor-waf-custom-rules-policy-properties.json](./frontdoor-waf-custom-rules-policy-properties.json): portable Azure Policy definition and source of truth. Edit this file to change the policy.
- [frontdoor-waf-custom-rules-policy.bicep](./frontdoor-waf-custom-rules-policy.bicep): management-group definition deployment, consuming the properties JSON.
- [frontdoor-waf-custom-rules-policy.json](./frontdoor-waf-custom-rules-policy.json): generated ARM management-group deployment template. Rebuild it after changing the properties JSON; do not edit it manually.
- [assignment.parameters.example.json](./assignment.parameters.example.json): audit-first assignment parameters. Replace the example rule before enabling remediation.
- [deployTemplate.json](./deployTemplate.json): standalone copy of the remediation template, with the same rule-action parameter and behavior.

## Parameters

| Parameter | Type | Description |
| --- | --- | --- |
| `customRules` | Array, required | 1-10 Front Door `CustomRule` objects, with at most 10 match conditions each. Pass objects directly, not `{ "rules": [...] }` or `{ "customRules": ... }`. |
| `ruleAction` | String | `Log` (default), `Allow`, `Block`, `Redirect`, `JSChallenge`, `CAPTCHA`, or `FromRule`. A specific action overrides every supplied rule's `action`; `FromRule` uses each object's action. |
| `effect` | String | `DeployIfNotExists` (default), `AuditIfNotExists`, or `Disabled`. |

For example, the `customRules` assignment parameter has this shape:

```json
{
  "customRules": {
    "value": [
      {
        "name": "LogDocumentationIP",
        "priority": 1,
        "enabledState": "Enabled",
        "ruleType": "MatchRule",
        "action": "Log",
        "matchConditions": [
          {
            "matchVariable": "RemoteAddr",
            "operator": "IPMatch",
            "matchValue": ["192.0.2.0/24"]
          }
        ]
      }
    ]
  },
  "ruleAction": {
    "value": "Log"
  }
}
```

The example uses a documentation-only IP range and `Log`, not a production blocking rule. For example, setting `"ruleAction": { "value": "Block" }` changes the desired action of every supplied managed rule to `Block`, even when the objects still say `"action": "Log"`. It does not change unrelated rules.

The portal display names map to these ARM values:

| Portal action | `ruleAction` value |
| --- | --- |
| Allow traffic | `Allow` |
| Deny traffic | `Block` |
| Log traffic only | `Log` |
| Redirect traffic | `Redirect` |
| JS Challenge | `JSChallenge` |
| CAPTCHA | `CAPTCHA` |

Supply rules appropriate to your WAF SKU, using valid, case-insensitively unique managed names and requested priorities from 1 through 1000. Names must start with a letter and contain only ASCII letters and digits. The suffix is appended once, case-insensitively. Unsuffixed names must leave room for its 14 characters within the service's 128-character name limit (at most 114 characters before suffixing). Other invalid characters in supplied names are not automatically removed. Requested priorities may overlap unrelated rules or other supplied rules; remediation resolves those conflicts.

Azure validates rule content and service quotas when remediation deploys. Both remediation templates enforce `minLength: 1` and `maxLength: 10`. Azure Policy does not enforce array-length constraints on assignment parameters, so empty or oversized assignments are explicitly noncompliant and fail remediation. The compliance loops are bounded to 10 supplied rules and 10 match conditions to stay within Azure Policy's 100 nested value-count iteration limit. Split larger rule sets across assignments with distinct managed names; do not have assignments enforce the same rule with conflicting intent.

## Behavior

- Targets `Microsoft.Network/frontdoorwebapplicationfirewallpolicies`, including Classic, Standard, and Premium Front Door WAF policies. It does not target Application Gateway WAF.
- Checks the **same policy by name**, not another WAF policy in the resource group.
- A supplied name such as `PhpFormNesting20` is managed as `PhpFormNesting20PolicyEnforced`. Already suffixed names are used as-is.
- A policy is compliant only when **every managed rule exists and matches the supplied configuration**, with the selected action and collision-resolved priority. Names are matched case-insensitively; conditions, values, transforms, condition order, enabled state, rule type, rate-limit settings, and grouping are checked.
- A matching managed rule is fully replaced with the desired settings when it drifts, including when enabled state or conditions change without an action change. This is not limited to correcting the action.
- Rules whose names do not match the current assignment's managed names are never changed, renumbered, enabled, disabled, or removed. This includes unsuffixed copies and suffixed rules belonging to other assignments.
- Managed rules are planned in parameter-array order. If a managed name repeats, only its first occurrence is enforced, including when one occurrence already has the suffix.
- Priorities occupied by unrelated rules are reserved first; old priorities of this assignment's managed rules are released before replanning. Each managed rule keeps its requested priority when available, including a requested priority below 100. Otherwise, it receives the **lowest unused priority from 100 through 1000**, accounting for unrelated rules and managed rules planned earlier.
- Compliance recognizes the deterministic allocated priority instead of repeatedly flagging it as different from an occupied requested priority. Moving a managed rule away from its correct allocated priority is still drift.
- If no fallback priority remains, template evaluation fails before the WAF write, even if priorities below 100 remain free. Exceeding the service's rule-count or SKU-specific quotas also fails deployment; the policy does not delete rules to make room.
- Missing, null, or empty `customRules.rules` is treated as an empty rule collection.
- Reads the latest WAF configuration during remediation, then uses a nested deployment to update the policy without a self-referencing resource dependency.
- Passes the evaluated policy's resource ID into the nested deployment and derives its name from that ID. The full ARM reference snapshot is used for configuration, not for a `name` property that may be absent.
- Rechecks the snapshot and skips the write when every managed rule already has the desired configuration.
- The write condition is `not(empty(changedRules))`. Root-level `condition`, `isConditionTrue`, and `existing` flags are ARM deployment metadata and do not control rule compliance or remediation.
- Normalizes omitted API defaults before comparing: rule `enabledState: Enabled`, rate-limit duration `1`, threshold `0`, and `groupBy: []`; condition `selector: null`, `negateCondition: false`, and `transforms: []`. Read-back defaults do not cause perpetual remediation.
- Preserves the existing location, tags, SKU, policy settings, and managed rules, including exclusions and overrides. Read-only properties such as associations and provisioning state are not sent in the update.
- For omitted optional properties, uses empty tags/settings/managed-rule sets and the API's default Classic SKU.
- New or updated resources are evaluated after successful provisioning. Existing resources require a remediation task.
- Adding a supplied name, changing its settings, or changing `ruleAction` makes affected policies noncompliant. Existing policies need a new remediation task; new or updated policies are remediated automatically with `DeployIfNotExists`.
- Removing a name from the assignment does not remove previously deployed rules; those rules are no longer managed by this assignment.

For example, if unrelated rules occupy priorities `1` and `100`, two supplied rules both requesting `1` receive `101` and `102`. Unrelated rules retain priorities `1` and `100`. Repeating remediation makes no further changes.

Preserving unrelated rules does not guarantee unchanged traffic handling: adding or changing managed rules changes WAF evaluation, and priority conflicts can alter their relative order. An existing Allow or Block rule can also short-circuit a managed rule. Test the combined rule set before broad rollout. Action availability and behavior depend on the WAF SKU and policy settings; for example, `Redirect` requires an appropriate policy redirect URL.

Remediation is a read-then-write operation, not an atomic conditional patch. Avoid concurrent WAF edits during remediation; an edit made after the snapshot can be overwritten. This policy does not associate a WAF policy with a Front Door endpoint or change its enforcement mode. It enforces the supplied enabled state, defaulting to `Enabled` when omitted.

Version 2.0.0 changes the original empty-only behavior to additive enforcement. Redeploy the definition and review audit compliance before enabling broader remediation.

Version 2.0.1 fixes remediation validation when `reference(..., 'Full')` does not expose a `name` property. Redeploy the definition before creating a new remediation task; retrying a deployment with the old template will retain the error.

Version 2.0.2 makes the missing-rule condition explicit and tests the supplied full-reference snapshot shape, including null settings values and ARM metadata.

**Version 3.0.0 is a behavior change:** it adds full configuration enforcement, managed-name suffixing, the default `Log` action override, a 10-rule assignment limit, and fallback allocation starting at 100. Redeploy the definition and review assignments in audit mode before remediation. Existing unsuffixed rules from version 2 remain untouched and do not satisfy compliance for their new suffixed counterparts. Review potential duplicate traffic handling before migrating; do not delete existing rules without an explicit operational decision.

**Version 3.0.1 fixes policy-definition validation:** Azure Policy rejects `current()` inside `count.value`, even when the count is nested in another count's `where`. Counts now iterate bounded, context-independent arrays; references to the outer rule or condition occur only inside `where`. Rule lookup is performed in condition expressions rather than a context-dependent singleton count. Full-setting enforcement, duplicate-name handling, and priority allocation are unchanged. Redeploy the corrected definition; retrying the version 3.0.0 definition retains the validation error.

**Version 3.0.2 removes numeric `current()` array indices:** compliance now iterates the supplied rule objects directly. Condition comparisons use fixed indices 0-9, with optional defaults normalized and the array length checked separately. This removes expressions such as `parameters('customRules')[current('ruleIndex')]` implicated in definition-time `InvalidPolicyParameters` errors reporting `'disabled'` as an invalid array index. The policy still detects full configuration drift and uses the same priority planning. Rebuild the generated deployment JSON before retrying.

**Version 3.0.3 fixes field-count property access:** field counts now use `current('.../customRules.rules[*].priority')` and `current('.../customRules.rules[*].name')` instead of accessing `.priority` or `.name` on `current('.../customRules.rules[*]')`. Azure Policy permits object property accessors on value-count variables, but field-count properties must be specified as aliases inside `current()`. All seven affected priority-planning references are corrected. Rebuild the generated deployment JSON before validating or deploying it.

**Version 3.0.4 guards nullable reference operands:** a default object around a rule lookup does not supply missing properties when that lookup returns a sparse, non-null object. Retrieved priorities are now explicitly coalesced to numeric `0`, retrieved names to an empty string, and retrieved condition/name/rule collections to empty arrays before comparison or indexing. These are comparison sentinels, not deployment values: `0` is outside the valid priority range and incomplete rules remain noncompliant. All six selected-rule priority lookups, nullable priority field-count operands, and related name/collection lookups are guarded. Sparse-reference tests exercise missing and explicit-null properties separately from remediation, which continues to require valid WAF rule objects.

**Version 3.0.5 fixes the managed rule suffix:** the suffix is now `PolicyEnforced` without a separator, because Front Door custom rule names allow letters and digits only. Compliance, duplicate-name detection, ownership, and remediation use the same case-insensitive suffix. Already suffixed names are not suffixed again. For example, `PhpFormNesting20` becomes `PhpFormNesting20PolicyEnforced`. Redeploy the definition and start a new remediation task; retrying an older remediation deployment retains its invalid rule-name expressions. Definition validation alone does not validate the WAF payload emitted by remediation.

## Deploy the Definition

Requires Azure CLI with Bicep support and permission to create management-group policy definitions.

From the repository root:

```powershell
$managementGroupId = '<management-group-id>'
$definitionName = 'deploy-frontdoor-waf-custom-rules'
$policyFolder = '.\Custom-Policies\FrontDoor-WAF-Custom-Rules'

az bicep build --file "$policyFolder\frontdoor-waf-custom-rules-policy.bicep"

az deployment mg create `
  --management-group-id $managementGroupId `
  --location eastus `
  --name frontdoor-waf-custom-rules-definition `
  --template-file "$policyFolder\frontdoor-waf-custom-rules-policy.bicep" `
  --parameters policyDefinitionName=$definitionName

$definitionId = "/providers/Microsoft.Management/managementGroups/$managementGroupId/providers/Microsoft.Authorization/policyDefinitions/$definitionName"
```

For Azure PowerShell, deploy the generated ARM template rather than the source properties JSON:

```powershell
$policyFolder = '.\Custom-Policies\FrontDoor-WAF-Custom-Rules'
az bicep build --file "$policyFolder\frontdoor-waf-custom-rules-policy.bicep"

Test-AzManagementGroupDeployment `
  -ManagementGroupId root `
  -Location eastus `
  -TemplateFile "$policyFolder\frontdoor-waf-custom-rules-policy.json"

New-AzManagementGroupDeployment `
  -Name FrontDoor `
  -ManagementGroupId root `
  -Location eastus `
  -TemplateFile "$policyFolder\frontdoor-waf-custom-rules-policy.json"
```

Replace `root` with your management-group ID. `Test-AzManagementGroupDeployment` validates without deploying resources; it requires a signed-in Azure PowerShell session with permissions at that scope. Definition validation is separate from WAF rule validation during assignment remediation.

For a subscription-level definition instead, change the Bicep `targetScope` to `subscription`, use `az deployment sub create`, and use `/subscriptions/<subscription-id>/providers/Microsoft.Authorization/policyDefinitions/<definition-name>` as the definition ID.

## Assign and Grant Remediation Permissions

First customize [assignment.parameters.example.json](./assignment.parameters.example.json), keeping `AuditIfNotExists` for the initial review. The subscription must be a descendant of the definition's management group.

```powershell
$subscriptionId = az account show --query id --output tsv
$scope = "/subscriptions/$subscriptionId"
$assignmentName = 'frontdoor-waf-custom-rules'

az policy assignment create `
  --name $assignmentName `
  --scope $scope `
  --policy $definitionId `
  --location eastus `
  --mi-system-assigned `
  --params "@$policyFolder\assignment.parameters.example.json"

$principalId = az policy assignment show `
  --name $assignmentName --scope $scope `
  --query identity.principalId --output tsv

az role assignment create `
  --assignee-object-id $principalId `
  --assignee-principal-type ServicePrincipal `
  --role '4d97b98b-1d4f-4787-a291-c67834d212e7' `
  --scope $scope
```

The assignment identity requires **Network Contributor**, which includes WAF writes and ARM deployments. Prefer a narrower assignment scope, such as a canary resource group, where possible. Creating role assignments requires Owner, Role Based Access Control Administrator, or equivalent permissions. The definition's `roleDefinitionIds` declares the required role but does not grant it automatically when assigning through CLI or Bicep.

## Verify and Remediate

1. Use canary WAF policies in the same resource group: one empty, one with unrelated rules whose priorities overlap the supplied rules, one with correctly configured suffixed managed rules, and one with managed-rule drift (action, enabled state, or conditions).
2. Run `az policy state trigger-scan --subscription $subscriptionId` and inspect compliance for the assignment. Only the policy containing all managed rules with the correct settings and resolved priorities should be compliant.
3. Change `effect.value` in the parameter file to `DeployIfNotExists`, then update the assignment:

   ```powershell
   az policy assignment update `
     --name $assignmentName --scope $scope `
     --params "@$policyFolder\assignment.parameters.example.json"
   ```

4. After the identity's role assignment has propagated, start remediation:

   ```powershell
   $assignmentId = az policy assignment show `
     --name $assignmentName --scope $scope --query id --output tsv

   az policy remediation create `
     --name frontdoor-waf-custom-rules-remediation `
     --policy-assignment $assignmentId `
     --resource-discovery-mode ReEvaluateCompliance
   ```

5. Inspect the remediation's deployment status. Confirm missing suffixed rules were added, drifted managed rules were replaced, conflicting priorities were allocated from 100, and every unrelated rule, tag, SKU, policy setting, and managed rule set remains unchanged.
6. Rescan compliance and repeat remediation to confirm no further changes. Change `ruleAction` to `Block`, then test `FromRule` with mixed per-rule actions. Test conditions-only and enabled-state-only drift, absent/null custom-rule collections, priority gaps, case-insensitive suffixed names, and invalid assignment sizes (which must fail deployment).
7. Create a new canary WAF policy after assignment. Confirm the supplied rules are added after successful provisioning without a separate remediation task.

No resources are deployed merely by adding these files or building the definition. Disabling or deleting the assignment stops future enforcement but does not remove custom rules already deployed.