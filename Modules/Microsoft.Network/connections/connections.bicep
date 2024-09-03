param name string
param location string
param tags object = {}
@allowed([
  'IPsec'
  'ExpressRoute'
])
param connectionType string
param virtualNetworkGateway1 string
param localNetworkGateway2 string = ''
@allowed([
  'IKEv1'
  'IKEv2'
])
param connectionProtocol string = 'IKEv2'
param enableBgp bool = true
param sharedKey string = ''
param usePolicyBasedTrafficSelectors bool = false
param authorizationKey string = ''
param erCircuitId string = ''
param ipsecCustomPolicy bool = false
@allowed([
  'AES128'
  'AES192'
  'AES256'
  'DES'
  'DES3'
  'GCMAES128'
  'GCMAES256'
])
param ikePhase1Encryption string = 'GCMAES256'
@allowed([
  'GCMAES128'
  'GCMAES256'
  'MD5'
  'SHA1'
  'SHA256'
  'SHA384'
])
param ikePhase1Integrity string = 'GCMAES256'
@allowed([
 'DHGroup1' 
 'DHGroup14'
 'DHGroup2'
 'DHGroup2048'
 'DHGroup24'
 'ECP256'
 'ECP384'
 'None' 
])
param ikePhase1DHGroup string = 'ECP384'
@allowed([
  'AES128'
  'AES192'
  'AES256'
  'DES'
  'DES3'
  'GCMAES128'
  'GCMAES192'
  'GCMAES256'
])
param ipsecPhase2Encryption string = 'GCMAES256'
@allowed([
  'GCMAES128'
  'GCMAES192'
  'GCMAES256'
  'MD5'
  'SHA1'
  'SHA256' 
])
param ipsecPhase2Integrity string = 'GCMAES256'
@allowed([
  'ECP256'
  'ECP384'
  'None'
  'PFS1'
  'PFS14'
  'PFS2'
  'PFS2048'
  'PFS24'
  'PFSMM'
])
param ipsecPhase2PFSGroup string = 'ECP384'
param saKBytes int = 102400000
param saLifeTime int = 27000

var properties = connectionType == 'IPsec' ? {
  connectionType: connectionType
  ipsecPolicies: ipsecCustomPolicy == true ? [
    {
      dhGroup: ikePhase1DHGroup
      ikeEncryption: ikePhase1Encryption
      ikeIntegrity: ikePhase1Integrity
      ipsecEncryption: ipsecPhase2Encryption
      ipsecIntegrity: ipsecPhase2Integrity
      pfsGroup: ipsecPhase2PFSGroup  
      saDataSizeKilobytes: saKBytes
      saLifeTimeSeconds: saLifeTime  
    }
  ] : []
  virtualNetworkGateway1: {
    id: virtualNetworkGateway1
    properties: reference(virtualNetworkGateway1, '2020-11-01', 'FULL').properties  
  }
  localNetworkGateway2: {
    id: localNetworkGateway2
    properties: reference(localNetworkGateway2, '2021-08-01', 'FULL').properties  
  }
  connectionMode: 'Default'
  connectionProtocol: connectionProtocol
  enableBgp: enableBgp
  sharedKey: sharedKey
  usePolicyBasedTrafficSelectors: usePolicyBasedTrafficSelectors         
} : {
  connectionType: connectionType
  virtualNetworkGateway1: {
    id: virtualNetworkGateway1
    properties: reference(virtualNetworkGateway1, '2020-11-01', 'FULL').properties  
  }
  authorizationKey: authorizationKey
  peer: {
    id: erCircuitId 
  }         
}

resource connection 'Microsoft.Network/connections@2021-08-01' = {
  name: name
  location: location
  tags: tags
  properties: properties
}
