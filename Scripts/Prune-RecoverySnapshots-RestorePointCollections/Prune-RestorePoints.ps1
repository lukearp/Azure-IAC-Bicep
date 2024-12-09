$query = @'
resources
| where type == "microsoft.compute/restorepointcollections"
'@

$result = Search-AzGraph -Query $query

foreach($collection in $result)
{
    Select-AzSubscription $collection.subscriptionId
    $restorePointCollection = Get-AzRestorePointCollection -Name $collection.name -ResourceGroupName $collection.resourceGroup
    $restorePointsToDelete = $restorePointCollection.RestorePoints | ?{$(Get-Date).AddDays(-2) -gt $_.TimeCreated}
    foreach($restorePoint in $restorePointsToDelete) {
        Remove-AzRestorePoint -ResourceGroupName $collection.resourceGroup -RestorePointCollectionName $collection.name -Name $restorePoint.Name
    }
}