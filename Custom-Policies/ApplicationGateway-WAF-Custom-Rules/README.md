# Application Gateway WAF Custom Rules

Enforces assignment-supplied custom rules on **Application Gateway WAF policy resources in the assignment scope**, including newly created policies. It uses the same management model as the [Front Door solution](../FrontDoor-WAF-Custom-Rules/README.md), but the Application Gateway rule schema and priority limits.

Managed names end in `PolicyEnforced`. Unrelated rules, policy settings, managed-rule overrides, exclusions, and exceptions are preserved. This solution does not create Application Gateways, attach policies to gateways/listeners, or migrate legacy inline WAF configuration.

## Files

- [applicationgateway-waf-custom-rules-policy-properties.json](./applicationgateway-waf-custom-rules-policy-properties.json): portable Azure Policy definition and editable source of truth.
- [applicationgateway-waf-custom-rules-policy.bicep](./applicationgateway-waf-custom-rules-policy.bicep): management-group deployment wrapper.
- [applicationgateway-waf-custom-rules-policy.json](./applicationgateway-waf-custom-rules-policy.json): generated management-group ARM template. Rebuild after changing the source; do not edit manually.
- [assignment.parameters.example.json](./assignment.parameters.example.json): audit-first parameters using a documentation-only IP range.

## Parameters

| Parameter | Type | Description |
| --- | --- | --- |
| `customRules` | Array, required | 1-10 Application Gateway custom-rule objects, with 1-10 conditions per rule and 1-10 match variables per condition. Pass the objects directly, without a `customRules` or `rules` wrapper. |
| `ruleAction` | String | `Log` (default), `Allow`, `Block`, `JSChallenge`, or `FromRule`. A specific action overrides every supplied rule's action; `FromRule` retains each object's action. |
| `effect` | String | `DeployIfNotExists` (default), `AuditIfNotExists`, or `Disabled`. |

### Application Gateway schema

This solution targets `Microsoft.Network/applicationGatewayWebApplicationFirewallPolicies` using API `2025-03-01`. Do not supply Front Door rule objects.

| Setting | Application Gateway | Front Door |
| --- | --- | --- |
| Rule enabled state | `state` | `enabledState` |
| Match variables | `matchVariables: [{ "variableName": "...", "selector": "..." }]` | `matchVariable` and optional condition-level `selector` |
| Match values | `matchValues` | `matchValue` |
| Negation | `negationConditon` (actual API spelling) | `negateCondition` |
| Regex operator | `Regex` | `RegEx` |
| Header variable | `RequestHeaders` | `RequestHeader` |
| Parsed POST arguments | `PostArgs` | Not the Application Gateway match-variable schema |
| Rate-limit duration | `rateLimitDuration`: `OneMin` or `FiveMins` | `rateLimitDurationInMinutes` |
| Rate-limit grouping | `groupByUserSession` with nested `groupByVariables` | `groupBy` |
| Resource custom rules | Direct `properties.customRules` array | `properties.customRules.rules` |
| Requested priorities | 1-100 | 1-1000 |

The misspelling `negationConditon` is intentional. Selectors belong inside the match-variable objects, not beside `operator`. Application Gateway does not support Front Door's `Redirect` or `CAPTCHA` custom-rule actions. `JSChallenge` and rate-limit rules require a service configuration that supports those features; Azure validates feature restrictions during remediation.

Example assignment parameters:

```json
{
  "customRules": {
    "value": [
      {
        "name": "PhpMultipartNesting20",
        "priority": 55,
        "state": "Enabled",
        "ruleType": "MatchRule",
        "action": "Log",
        "matchConditions": [
          {
            "matchVariables": [
              { "variableName": "RequestHeaders", "selector": "Content-Type" }
            ],
            "operator": "BeginsWith",
            "negationConditon": false,
            "transforms": ["Trim", "Lowercase"],
            "matchValues": ["multipart/form-data"]
          },
          {
            "matchVariables": [{ "variableName": "PostArgs" }],
            "operator": "Regex",
            "negationConditon": false,
            "transforms": [],
            "matchValues": ["^[^\\[\\]]+(?:\\[[^\\]]*\\]){20}"]
          }
        ]
      }
    ]
  },
  "ruleAction": { "value": "Log" },
  "effect": { "value": "AuditIfNotExists" }
}
```

This illustrates the Application Gateway payload shape, not a verified PHP-exploit detection guarantee. Validate parsing, regex support, and detection behavior against representative requests on a test gateway before using `Block`.

For a rate-limit rule, supply `ruleType: RateLimitRule`, an explicit `rateLimitDuration`, a positive `rateLimitThreshold`, and the intended grouping, for example:

```json
{
  "groupByUserSession": [
    { "groupByVariables": [{ "variableName": "ClientAddr" }] }
  ]
}
```

Rate-limit duration and threshold are not copied from Front Door defaults. See the [Application Gateway custom-rule overview](https://learn.microsoft.com/en-us/azure/web-application-firewall/ag/custom-waf-rules-overview) and [API schema](https://learn.microsoft.com/en-us/azure/templates/microsoft.network/2025-03-01/applicationgatewaywebapplicationfirewallpolicies) for supported values and restrictions.

## Enforcement behavior

- Checks the **same WAF policy by name**, not another policy in the resource group. Only Application Gateway WAF policy resources are targeted.
- Appends `PolicyEnforced` once, case-insensitively: `PhpMultipartNesting20` becomes `PhpMultipartNesting20PolicyEnforced`. Names must start with a letter and contain only ASCII letters and digits. Leave room for the 14-character suffix within the 128-character rule-name limit: at most 114 characters before suffixing. Invalid characters are not automatically removed.
- Only names supplied by this assignment are managed. Unsuffixed copies, unrelated rules, and suffixed rules belonging to other assignments are preserved. Duplicate normalized names use their first supplied definition.
- Enforces the complete writable managed-rule configuration, including `state`, action, rule type, condition/variable/value/transform ordering, case-sensitive match values/selectors, rate-limit duration/threshold, and grouping. It is not just an existence or action check.
- Plans managed rules in supplied-array order. Reserves unrelated priorities first and releases all priorities of this assignment's existing managed rules before replanning.
- Keeps the requested priority when it is free, including requested priorities below 50. Otherwise allocates the **lowest unused priority from 50 through 100**, accounting for unrelated rules and earlier planned managed rules. For example, unrelated priorities `1`, `50`, and `52`, combined with requested priorities `1`, `1`, and `4`, yield managed priorities `51`, `53`, and `4`.
- Compliance recognizes that deterministic priority plan. Moving a rule away from its allocated priority remains drift; an occupied requested priority does not cause endless remediation.
- If all fallback priorities are occupied, remediation fails before writing the WAF policy, **even if values below 50 remain unused**. Application Gateway supports at most 100 custom rules; service quota or feature failures also fail deployment. No unrelated rule is deleted to make room.
- Normalizes omitted rule `state` to `Enabled`, omitted grouping to `[]`, omitted condition negation to `false`, omitted transforms to `[]`, and omitted nested selectors to `null`. Read-only custom-rule `etag` values are ignored for comparison and omitted from the write, including on preserved unrelated rules.
- Missing, null, or empty `properties.customRules` is treated as an empty collection. Explicit nulls for other rule settings are not a substitute for valid API values.
- Reads the latest full resource reference and passes it to a nested deployment, avoiding a self-referencing resource dependency. Derives the target resource name from its ID, not an optional snapshot `name`.
- Writes only if at least one managed rule is missing or differs. Root snapshot metadata such as `condition`, `existing`, and `isConditionTrue` does not control this decision.
- Preserves regional location, tags, policy settings (including boolean request-body settings), and the complete required `managedRules` object, including exclusions and exceptions. Does not send Front Door SKU or read-only gateway/listener/path associations, resource state, provisioning state, or root/rule etags.
- New and updated policies are evaluated after successful provisioning. Existing policies need a remediation task. Changing assignment rules or `ruleAction` requires a **new remediation task** for existing policies; retrying an old failed deployment reuses its old template and parameters.
- Removing a name from the assignment does not delete a previously deployed rule; it simply stops managing that name.

### Bounds and operational considerations

Azure Policy assignment arrays do not support the nested ARM parameter constraints used here. Empty or oversized rule arrays and unsupported rule/condition/variable bounds are noncompliant. Remediation enforces 1-10 supplied rules and rejects rules outside priority 1-100, 1-10 conditions, or 1-10 match variables before any WAF write. Its internal `invalidRuleCount` parameter must be zero and is computed by the enclosing template; it is not an assignment parameter.

Compliance uses bounded value counts and fixed variable slots to remain within Azure Policy authoring/evaluation limits, including 100 nested value-count iterations. Larger rule sets can use separate assignments with distinct managed names. Do not let assignments enforce the same managed name with conflicting intent.

The resource update is a read-then-write operation, not an atomic patch. Concurrent manual changes or competing remediations can overwrite one another. Coordinate edits and assignments. Start in audit mode, review the resulting rule configuration, and test a canary policy before broad remediation.

## Build, validate, and deploy the definition

Run from this folder. Build after changing the properties JSON:

```powershell
az bicep build --file .\applicationgateway-waf-custom-rules-policy.bicep
```

The equivalent direct CLI command is `bicep build .\applicationgateway-waf-custom-rules-policy.bicep`. If Azure CLI installed Bicep outside PATH, use `& "$HOME\.azure\bin\bicep.exe" build .\applicationgateway-waf-custom-rules-policy.bicep`.

Validate without deploying, then deploy the management-group definition with an authorized identity:

```powershell
Test-AzManagementGroupDeployment `
  -ManagementGroupId root -Location eastus `
  -TemplateFile .\applicationgateway-waf-custom-rules-policy.json

New-AzManagementGroupDeployment `
  -Name ApplicationGatewayWafCustomRules `
  -ManagementGroupId root -Location eastus `
  -TemplateFile .\applicationgateway-waf-custom-rules-policy.json
```

The wrapper's optional `policyDefinitionName` defaults to `deploy-applicationgateway-waf-custom-rules`. These commands create the definition only; they do not create an assignment.

Assign the definition at the intended scope with the example parameters, initially using `AuditIfNotExists`. For `DeployIfNotExists`, use an assignment managed identity and grant it the **Network Contributor** role at the target scope:

`/providers/Microsoft.Authorization/roleDefinitions/4d97b98b-1d4f-4787-a291-c67834d212e7`

Creating an assignment with PowerShell/CLI does not itself guarantee the identity's role assignment. Confirm the role and create a remediation task for existing policies after reviewing compliance.

The standalone [deployTemplate.json](./deployTemplate.json) can also be deployed at the target WAF policy's resource group using `policyResourceId`, `customRules`, and optional `ruleAction`. It modifies the WAF policy; management-group definition validation does not validate this service-side write or regex detection behavior.