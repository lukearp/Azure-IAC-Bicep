param vnetSubnets array = [
  {
    name: 'mysub'
    addressPrefix: '10.0.0.0/27'
    networkSecurityGroup: {
      name: 'NSG_mysub'
      rules: []
    }
    routeTable: 'testRT'
  }
  {
    name: 'mysub2'
    addressPrefix: '10.0.0.32/27'
    networkSecurityGroup: {
      name: 'NSG_mysub'
      rules: []
    }
    routeTable: null
  }
  {
    name: 'mysub3'
    addressPrefix: '10.0.0.64/27'
    networkSecurityGroup: null
    routeTable: null
  }
]

var testJsonString = [for subnet in vnetSubnets: subnet.networkSecurityGroup == null ? {
  name: subnet.name
  addressPrefix: subnet.addressPrefix
} : {
  name: subnet.name
  addressPrefix: subnet.addressPrefix
  networkSecurityGroup: subnet.networkSecurityGroup
  routeTable: subnet.routeTable
}]

output jsonResult array = testJsonString
