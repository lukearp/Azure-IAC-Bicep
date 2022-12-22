param location string
param mlWorkspaceName string

module hostPool '../../Modules/Microsoft.DesktopVirtualization/hostpools.bicep' = {
  name: '${mlWorkspaceName}-AVD-Hostpool'
  params: {
    loadBalancerType: 'BreadthFirst'
    location: location
    name: '${mlWorkspaceName}-AVD-Hostpool'
    hostPoolType: 'Pooled'
    preferredAppGroupType: 'Desktop'     
  }  
}

module appGroup '../../Modules/Microsoft.DesktopVirtualization/applicationgroups.bicep' = {
  name: '${mlWorkspaceName}-AVD-AppGroup'
  params: {
    applicationGroupType: 'Desktop'
    hostpoolResourceId: hostPool.outputs.id
    description: 'Desktop App Group'
    location: location
    name: '${mlWorkspaceName}-AVD-AppGroup'    
  }  
}

module avdWorkspace '../../Modules/Microsoft.DesktopVirtualization/workspaces.bicep' = {
  name: '${mlWorkspaceName}-AVD-Workspace'
  params: {
    description: 'Access to private ML Workspace'
    location: location
    name: '${mlWorkspaceName}-AVD-Workspace'
    applicationGroupReferences: [
      appGroup.outputs.id
    ]     
  }   
}
