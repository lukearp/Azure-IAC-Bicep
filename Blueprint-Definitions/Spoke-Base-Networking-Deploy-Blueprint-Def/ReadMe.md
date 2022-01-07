# Sample Module

Script to make the [Spoke-Base-Networking-Deploy](https://github.com/lukearp/Azure-IAC-Bicep/tree/master/Standard-Deployments/Spoke-Base-Networking-Deploy) Standard Deploy a Blueprint Definition

```
az bicep build --file ../../Starndard-Deployments/Spoke-Base-Networking-Deploy/Spoke-Blueprint.bicep
az bicep build --file blueprintDef.bicep
az deployment mg create --name BlueprintDef --management-group-id TargetMG --location eastus --template-file blueprintDef.json --parameters '{ \"blueprintName\": { \"value\": \"BLUEPRINTNAME\" },\"displayName\": { \"value\": \"DISPLAY NAME\" },\"description\": { \"value\": \"DESCRIPTION\" } }'
az extension add --name blueprint --yes
az blueprint publish -m TargetMG --blueprint-name BLUEPRINTNAME --version $(Build.BuildId)
```