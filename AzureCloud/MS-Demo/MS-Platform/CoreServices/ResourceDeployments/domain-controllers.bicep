var domainName = 'lukesprojects.com'



module dc '../../../../../Standard-Deployments/DomainController/DomainController.bicep' = {
  name: '${domainName}-DomainController-Deployment'
  params: {
     
  }  
}
