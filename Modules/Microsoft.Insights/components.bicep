param name string
param location string
@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccessForIngestion string
@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccessForQuery string
param tags object

resource appInsight 'Microsoft.Insights/components@2020-02-02' = {
  kind: 'web'
  location: location
  name: name
  tags: tags
  properties: {
    Application_Type: 'web'
    RetentionInDays: 90
    IngestionMode: 'ApplicationInsights'
    publicNetworkAccessForIngestion: publicNetworkAccessForIngestion
    publicNetworkAccessForQuery: publicNetworkAccessForQuery   
  }    
}

output appInsightId string = appInsight.id
