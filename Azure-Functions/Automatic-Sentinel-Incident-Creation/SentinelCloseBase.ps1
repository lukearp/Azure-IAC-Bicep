$workspaceResourceGroup = $env:workspaceResourceGroup
$workspaceName = $env:workspaceName
$incident = Get-AzSentinelIncident -WorkspaceName $workspaceName -ResourceGroupName $workspaceResourceGroup -Id $eventHubMessages.object.name
if($null -ne $incident)
{
    if($null -eq $eventHubMessages.object.properties.classificationReason)
    {
        Update-AzSentinelIncident -ResourceGroupName $workspaceResourceGroup -WorkspaceName $workspaceName -Id $eventHubMessages.object.name -Status 'Closed' -Title $eventHubMessages.object.properties.title -Severity $eventHubMessages.object.properties.severity -Classification $eventHubMessages.object.properties.classification -ClassificationComment $eventHubMessages.object.properties.classificationComment 
    }
    else {
        Update-AzSentinelIncident -ResourceGroupName $workspaceResourceGroup -WorkspaceName $workspaceName -Id $eventHubMessages.object.name -Status 'Closed' -Title $eventHubMessages.object.properties.title -Severity $eventHubMessages.object.properties.severity -Classification $eventHubMessages.object.properties.classification -ClassificationComment $eventHubMessages.object.properties.classificationComment -ClassificationReason $eventHubMessages.object.properties.classificationReason
    }
}
