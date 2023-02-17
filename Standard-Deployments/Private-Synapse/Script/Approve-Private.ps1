param(
    $resourceId
)
$connections = Get-AzPrivateEndpointConnection -PrivateLinkResourceId $resourceId | ?{$_.PrivateLinkServiceConnectionState.Status -eq "Pending"}
foreach($connection in $connections) {
    Approve-AzPrivateEndpointConnection -ResourceId $connection.Id
}    