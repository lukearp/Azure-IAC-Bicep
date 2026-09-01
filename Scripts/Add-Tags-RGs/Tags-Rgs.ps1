<#
.SYNOPSIS
    Imports a CSV and applies tags to Resource Groups across one or more subscriptions.

.DESCRIPTION
    The CSV must contain a "SubscriptionId" column and a "ResourceGroupName" column.
    Every other column is treated as a tag, where the column header is the tag name
    and the cell value is the tag value for that row. Empty tag values are skipped.

.PARAMETER CsvPath
    Path to the CSV file to import.

.PARAMETER Operation
    Merge (default) adds/updates the specified tags and leaves existing tags in place.
    Replace overwrites all existing tags on the Resource Group with only the tags from the CSV.

.EXAMPLE
    .\Tags-Rgs.ps1 -CsvPath .\rg-tags.csv

.EXAMPLE
    .\Tags-Rgs.ps1 -CsvPath .\rg-tags.csv -Operation Replace
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path $_ })]
    [string]$CsvPath,

    [Parameter(Mandatory = $false)]
    [ValidateSet('Merge', 'Replace')]
    [string]$Operation = 'Merge'
)

$rows = Import-Csv -Path $CsvPath

if (-not $rows) {
    throw "No rows found in CSV: $CsvPath"
}

$requiredColumns = 'SubscriptionId', 'ResourceGroupName'
$columns = $rows[0].PSObject.Properties.Name
foreach ($required in $requiredColumns) {
    if ($required -notin $columns) {
        throw "CSV is missing required column: $required"
    }
}

$tagColumns = $columns | Where-Object { $_ -notin $requiredColumns }

$currentSubscriptionId = $null

foreach ($row in $rows) {
    $subscriptionId = $row.SubscriptionId
    $resourceGroupName = $row.ResourceGroupName

    if ([string]::IsNullOrWhiteSpace($subscriptionId) -or [string]::IsNullOrWhiteSpace($resourceGroupName)) {
        Write-Warning "Skipping row with missing SubscriptionId or ResourceGroupName."
        continue
    }

    if ($subscriptionId -ne $currentSubscriptionId) {
        Write-Host "Switching to subscription $subscriptionId"
        Select-AzSubscription -SubscriptionId $subscriptionId | Out-Null
        $currentSubscriptionId = $subscriptionId
    }

    $tags = @{}
    foreach ($tagColumn in $tagColumns) {
        $value = $row.$tagColumn
        if (-not [string]::IsNullOrWhiteSpace($value)) {
            $tags[$tagColumn] = $value
        }
    }

    if ($tags.Count -eq 0) {
        Write-Warning "No tag values found for Resource Group '$resourceGroupName' in subscription '$subscriptionId'. Skipping."
        continue
    }

    $rg = Get-AzResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue
    if (-not $rg) {
        Write-Warning "Resource Group '$resourceGroupName' not found in subscription '$subscriptionId'. Skipping."
        continue
    }

    Write-Host "Applying tags to '$resourceGroupName' ($Operation): $($tags.Keys -join ', ')"
    Update-AzTag -ResourceId $rg.ResourceId -Tag $tags -Operation $Operation | Out-Null
}
