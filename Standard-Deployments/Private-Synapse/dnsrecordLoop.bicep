param records array
param azureGovernment bool

var sqlDns = azureGovernment == false ? 'privatelink.sql.azuresynapse.net' : 'privatelink.sql.azuresynapse.usgovcloudapi.net'
var sqlNonPrivateDns = azureGovernment == false ? 'sql.azuresynapse.net' : 'sql.azuresynapse.usgovcloudapi.net'
var devDns = azureGovernment == false ? 'privatelink.dev.azuresynapse.net' : 'privatelink.dev.azuresynapse.usgovcloudapi.net'
var devNonPrivateDns = azureGovernment == false ? 'dev.azuresynapse.net' : 'dev.azuresynapse.usgovcloudapi.net'

module aRecords '../../Modules/Microsoft.Network/privateDnsZones/DNSRecord/dnsRecord.bicep' = [for record in records: {
  name: '${guid(record.fqdn)}-ARecord'
  params: {
    dnsZoneName: contains(record.fqdn,devNonPrivateDns) ? devDns : sqlDns
    hostName: contains(record.fqdn,devNonPrivateDns) ? split(record.fqdn,'.${devNonPrivateDns}')[0] : split(record.fqdn,'.${sqlNonPrivateDns}')[0]
    recordTarget: record.ipAddresses[0]
    recordType: 'A'
    recordTtl: 300  
  }  
}] 
