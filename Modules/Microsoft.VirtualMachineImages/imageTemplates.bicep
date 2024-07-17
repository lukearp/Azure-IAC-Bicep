param name string
param location string
param tags object = {} 
param offer string = ''
param publisher string = ''
param sku string = ''
@allowed([
  'PlatformImage'
  'SharedImageVersion'
])
param imageType string = 'PlatformImage'
param imageVersionId string = ''
param version string = 'latest'
param distributeImageId string
param userIdentityId string
param customize array = []

var source = imageType == 'SharedImageVersion' ? {
  type: 'SharedImageVersion'
  imageVersionId: imageVersionId           
} : {
  type: 'PlatformImage'  
  offer: offer
  publisher: publisher
  sku: sku
  version: version          
}

resource image 'Microsoft.VirtualMachineImages/imageTemplates@2022-02-14' = {
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
       '${userIdentityId}':{}
    }   
  }
  location: location
  name: name
  tags: tags
  properties: {
    source: source
    distribute: [
      {
        type: 'SharedImage'
        replicationRegions: [
          'eastus' 
        ]
        galleryImageId: distributeImageId
        runOutputName: guid(name)  
      }
    ]
    //customize: customize 
  }     
}
