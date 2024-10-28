$workspaceResourceGroup = $env:workspaceResourceGroup
$workspaceName = $env:workspaceName
$incident = @{
    title = $eventHubMessages.object.properties.title
    description = $eventHubMessages.object.properties.description
    severity = $eventHubMessages.object.properties.severity
    status = $eventHubMessages.object.properties.status
    owner = $eventHubMessages.object.properties.owner 
    labels = $eventHubMessages.object.properties.labels
    firstActivityTimeUtc = $eventHubMessages.object.properties.firstActivityTimeUtc
    lastActivityTimeUtc = $eventHubMessages.object.properties.lastActivityTimeUtc
    lastModifiedTimeUtc = $eventHubMessages.object.properties.lastModifiedTimeUtc
    createdTimeUtc = $eventHubMessages.object.properties.createdTimeUtc
    incidentNumber = $eventHubMessages.object.properties.incidentNumber
    additionalData = $eventHubMessages.object.properties.additionalData
    relatedAnalyticRuleIds = $eventHubMessages.object.properties.relatedAnalyticRuleIds
    incidentUrl = $eventHubMessages.object.properties.incidentUrl
    providerName = $eventHubMessages.object.properties.providerName
    providerIncidentId = $eventHubMessages.object.properties.providerIncidentId
    alerts = $eventHubMessages.object.properties.alerts
    bookmarks = $eventHubMessages.object.properties.bookmarks
    relatedEntities = $eventHubMessages.object.properties.relatedEntities
    comments = $eventHubMessages.object.properties.comments
}
New-AzSentinelIncident -ResourceGroupName $workspaceResourceGroup -WorkspaceName $workspaceName -Incident $incident -id $eventHubMessages.object.name