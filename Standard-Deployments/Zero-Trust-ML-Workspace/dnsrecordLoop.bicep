param records array
param azureGovernment bool

var mlApiDns = azureGovernment == false ? 'privatelink.api.azureml.ms' : 'privatelink.api.ml.azure.us'
var mlApiNonPrivateDns = azureGovernment == false ? 'api.azureml.ms' : 'api.ml.azure.us'
var mlNotbookDns = azureGovernment == false ? 'privatelink.notebooks.azure.net' : 'privatelink.notebooks.usgovcloudapi.net'
var mlNotbookNonPrivateDns = azureGovernment == false ? 'notebooks.azure.net' : 'notebooks.usgovcloudapi.net'

module aRecords '../../Modules/Microsoft.Network/privateDnsZones/DNSRecord/dnsRecord.bicep' = [for record in records: {
  name: '${guid(record.fqdn)}-ARecord'
  params: {
    dnsZoneName: contains(record.fqdn,mlApiNonPrivateDns) ? mlApiDns : mlNotbookDns
    hostName: contains(record.fqdn,mlApiNonPrivateDns) ? split(record.fqdn,'.${mlApiNonPrivateDns}')[0] : split(record.fqdn,'.${mlNotbookNonPrivateDns}')[0]
    recordTarget: record.ipAddresses[0]
    recordType: 'A'
    recordTtl: 300  
  }  
}] 
