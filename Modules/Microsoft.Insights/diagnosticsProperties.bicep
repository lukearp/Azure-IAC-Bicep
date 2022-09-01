param eventHubAuthorizationRuleId string = ''
param eventHubName string = ''
param serviceBusRuleId string = ''
param marketplacePartnerId string = ''
param storageAccountId string = ''
param workspaceId string = ''
param logs array = []
param metrics array = []

var diagProperties = workspaceId != '' && storageAccountId != '' ? {
  logs: logs
  metrics: metrics
  storageAccountId: storageAccountId
  workspaceId: workspaceId     
} : workspaceId != '' && storageAccountId == '' ? {
  logs: logs
  metrics: metrics
  workspaceId: workspaceId     
} : {
  logs: logs
  metrics: metrics
  workspaceId: workspaceId     
}

output properties object = diagProperties

/*
var diagProperties = workspaceId != '' && storageAccountId != '' && eventHubAuthorizationRuleId != '' && serviceBusRuleId != '' && eventHubName != '' ? {
  logs: logs
  eventHubAuthorizationRuleId: eventHubAuthorizationRuleId
  eventHubName: eventHubName
  serviceBusRuleId: serviceBusRuleId
  storageAccountId: storageAccountId
  workspaceId: workspaceId     
} : workspaceId != '' && storageAccountId != '' && eventHubAuthorizationRuleId != '' && serviceBusRuleId != '' && eventHubName == '' ? {
  logs: logs
  eventHubAuthorizationRuleId: eventHubAuthorizationRuleId
  serviceBusRuleId: serviceBusRuleId
  storageAccountId: storageAccountId
  workspaceId: workspaceId     
} : workspaceId != '' && storageAccountId != '' && eventHubAuthorizationRuleId != '' && serviceBusRuleId == '' && eventHubName != '' ? {
  logs: logs
  eventHubAuthorizationRuleId: eventHubAuthorizationRuleId
  eventHubName: eventHubName
  storageAccountId: storageAccountId
  workspaceId: workspaceId     
} : workspaceId != '' && storageAccountId != '' && eventHubAuthorizationRuleId == '' && serviceBusRuleId != '' && eventHubName != '' ? {
  logs: logs
  eventHubName: eventHubName
  serviceBusRuleId: serviceBusRuleId
  storageAccountId: storageAccountId
  workspaceId: workspaceId     
} : workspaceId != '' && storageAccountId == '' && eventHubAuthorizationRuleId != '' && serviceBusRuleId != '' && eventHubName != '' ? {
  logs: logs
  eventHubAuthorizationRuleId: eventHubAuthorizationRuleId
  eventHubName: eventHubName
  serviceBusRuleId: serviceBusRuleId
  workspaceId: workspaceId     
} : workspaceId == '' && storageAccountId != '' && eventHubAuthorizationRuleId != '' && serviceBusRuleId != '' && eventHubName != '' ? {
  logs: logs
  eventHubAuthorizationRuleId: eventHubAuthorizationRuleId
  serviceBusRuleId: serviceBusRuleId
  storageAccountId: storageAccountId    
} : workspaceId != '' && storageAccountId != '' && eventHubAuthorizationRuleId != '' && serviceBusRuleId == '' && eventHubName == '' ? {
  logs: logs
  eventHubAuthorizationRuleId: eventHubAuthorizationRuleId
  storageAccountId: storageAccountId
  workspaceId: workspaceId     
}
*/
