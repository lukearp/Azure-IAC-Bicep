extension microsoftGraph
param GroupName string
param DisplayName string
param Members array = []
param mailEnabled bool = false
param securityGroup bool = true

resource entraGroup 'Microsoft.Graph/groups@v1.0' = {
   displayName: DisplayName
   uniqueName: GroupName
   members: Members
   mailEnabled: mailEnabled
   mailNickname: GroupName
   securityEnabled: securityGroup   
}

output objectId string = entraGroup.id
