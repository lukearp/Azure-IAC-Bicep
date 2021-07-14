param name string
param privateIPAllocationMethod string = ''
param privateIPAddress string = ''
param publicIPId string
param subnetId string

var properties = privateIPAllocationMethod == '' && publicIPId != '' ? {
  publicIPAddress: {
    id: publicIPId
  }
} : privateIPAllocationMethod == 'Static' ? {
  privateIPAllocationMethod: 'Dynamic'
  subnet: {
    id: subnetId
  }
} : {
  privateIPAllocationMethod: privateIPAllocationMethod
  privateIPAddress: privateIPAddress
  subnet: {
    id: subnetId
  }
}

var frontendPort = {
  id: 'string'
  properties: properties
  name: name
}

output frontendObj object = frontendPort
