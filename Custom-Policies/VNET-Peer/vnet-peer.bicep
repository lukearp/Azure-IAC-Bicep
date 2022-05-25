targetScope = 'managementGroup'
param policyName string
/*
@allowed([
  'deployIfNotExists'
  'AuditIfNotExists'
  'disable'
])
param effect string
param tagKey string
param tagValue string
param regions array
param hubVnetId string
*/

module vnetPolicy '../../Modules/Microsoft.Authorization/policyDefinitions/policyDefinitions-mg.bicep' = { 
  name: '${policyName}-deployment'
  params: {
    dispalyName: policyName
    mode: 'Indexed'
    name: policyName
    parameters: {
       tagKey: {
         type: 'string'
       }
       tagValue: {
         type: 'string'
       }
       hubVnetId: {
         type: 'string'
       }
       regions: {
         type: 'array'
       }
       peeringName: {
         type: 'string'
       }
       effect: {
         type: 'string'
         allowedValues: [
           'deployIfNotExists'
           'AuditIfNotExists'
           'disable'
         ]
       }
    }
    policyRule: {
       if: {
         allOf: [
           {
            field: 'type'
            equals: 'Microsoft.Network/virtualNetworks'
           }
           {
            field: 'location'
            in: '[parameters(\'regions\')]'
           }
           {
             field: '[concat(\'tags[\', parameters(\'tagKey\'), \']\')]'
             equals: '[parameters(\'tagValue\')]'
           }
         ]
       }
       then: {
         effect: '[parameters(\'effect\')]'
         details: {
           roleDefinitionIds: [
             '/providers/microsoft.authorization/roleDefinitions/4d97b98b-1d4f-4787-a291-c67834d212e7'
           ]
           type: 'Microsoft.Network/virtualNetworks'
           existenceCondition: {
             allOf: [
              {
                field: 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings[*].name'
                equals: '[parameters(\'peeringName\')]'
              }
             ]
           }
           deployment: {
             properties: {
               mode: 'incremental'
               parameters: {
                vnetName: {
                  value: '[field(\'name\')]'
                }
                peeringName: {
                  value: '[parameters(\'peeringName\')]'
                }
                hubVnetId: {
                  value: '[parameters(\'hubVnetId\')]'
                }
               }
               template: {
                '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#'
                  contentVersion:  '1.0.0.0'
                  metadata:  {
                    _generator:  {
                      name:  'bicep'
                      version:  '0.5.6.12127'
                      templateHash:  '14238381296817479404'
                    }
                  }
                  parameters:  {
                    vnetName:  {
                      type:  'string'
                    }
                    peeringName:  {
                      type:  'string'
                    }
                    hubVnetId:  {
                      type:  'string'
                    }
                  }
                  resources:  [
                    {
                      type:  'Microsoft.Network/virtualNetworks/virtualNetworkPeerings'
                      apiVersion:  '2021-08-01'
                      name:  '[format(\'{0}/{1}\', parameters(\'vnetName\'), parameters(\'peeringName\'))]'
                      properties:  {
                        allowForwardedTraffic:  true
                        useRemoteGateways:  true
                        allowVirtualNetworkAccess:  true
                        remoteVirtualNetwork:  {
                          id:  '[parameters(\'hubVnetId\')]'
                        }
                      }
                    }
                    {
                      type:  'Microsoft.Resources/deployments'
                      apiVersion:  '2020-10-01'
                      name:  '[format(\'Hub-Peer-{0}\', parameters(\'vnetName\'))]'
                      subscriptionId:  '[split(parameters(\'hubVnetId\'), \'/\')[2]]'
                      resourceGroup:  '[split(parameters(\'hubVnetId\'), \'/\')[4]]'
                      properties:  {
                        expressionEvaluationOptions:  {
                          scope:  'inner'
                        }
                        mode:  'Incremental'
                        parameters:  {
                          allowGatewayTransit:  {
                            value:  true
                          }
                          allowForwardedTraffic:  {
                            value:  true
                          }
                          allowVnetAccess:  {
                            value:  true
                          }
                          peeringName:  {
                            value:  '[format(\'To-{0}\', parameters(\'vnetName\'))]'
                          }
                          remoteNetworkId:  {
                            value:  '[resourceId(\'Microsoft.Network/virtualNetworks\', parameters(\'vnetName\'))]'
                          }
                          useRemoteGateway:  {
                            value:  false
                          }
                          vnetName:  {
                            value:  '[split(parameters(\'hubVnetId\'), \'/\')[8]]'
                          }
                        }
                        template:  {
                '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#'
                          contentVersion:  '1.0.0.0'
                          metadata:  {
                            _generator:  {
                              name:  'bicep'
                              version:  '0.5.6.12127'
                              templateHash:  '13635323259117041300'
                            }
                          }
                          parameters:  {
                            peeringName:  {
                              type:  'string'
                            }
                            vnetName:  {
                              type:  'string'
                            }
                            remoteNetworkId:  {
                              type:  'string'
                            }
                            allowGatewayTransit:  {
                              type:  'bool'
                            }
                            useRemoteGateway:  {
                              type:  'bool'
                            }
                            allowForwardedTraffic:  {
                              type:  'bool'
                            }
                            allowVnetAccess:  {
                              type:  'bool'
                            }
                          }
                          resources:  [
                            {
                              condition:  '[and(equals(parameters(\'useRemoteGateway\'), true()), equals(parameters(\'allowGatewayTransit\'), false()))]'
                              type:  'Microsoft.Network/virtualNetworks/virtualNetworkPeerings'
                              apiVersion:  '2021-08-01'
                              name:  '[format(\'{0}/{1}\', parameters(\'vnetName\'), parameters(\'peeringName\'))]'
                              properties:  {
                                allowForwardedTraffic:  '[parameters(\'allowForwardedTraffic\')]'
                                useRemoteGateways:  '[parameters(\'useRemoteGateway\')]'
                                allowVirtualNetworkAccess:  '[parameters(\'allowVnetAccess\')]'
                                remoteVirtualNetwork:  {
                                  id:  '[parameters(\'remoteNetworkId\')]'
                                }
                              }
                            }
                            {
                              condition:  '[and(equals(parameters(\'allowGatewayTransit\'), true()), equals(parameters(\'useRemoteGateway\'), false()))]'
                              type:  'Microsoft.Network/virtualNetworks/virtualNetworkPeerings'
                              apiVersion:  '2021-08-01'
                              name:  '[format(\'{0}/{1}\', parameters(\'vnetName\'), parameters(\'peeringName\'))]'
                              properties:  {
                                allowForwardedTraffic:  '[parameters(\'allowForwardedTraffic\')]'
                                allowGatewayTransit:  '[parameters(\'allowGatewayTransit\')]'
                                allowVirtualNetworkAccess:  '[parameters(\'allowVnetAccess\')]'
                                remoteVirtualNetwork:  {
                                  id:  '[parameters(\'remoteNetworkId\')]'
                                }
                              }
                            }
                            {
                              condition:  '[and(equals(parameters(\'allowGatewayTransit\'), false()), equals(parameters(\'useRemoteGateway\'), false()))]'
                              type:  'Microsoft.Network/virtualNetworks/virtualNetworkPeerings'
                              apiVersion:  '2021-08-01'
                              name:  '[format(\'{0}/{1}\', parameters(\'vnetName\'), parameters(\'peeringName\'))]'
                              properties:  {
                                allowForwardedTraffic:  '[parameters(\'allowForwardedTraffic\')]'
                                allowVirtualNetworkAccess:  '[parameters(\'allowVnetAccess\')]'
                                remoteVirtualNetwork:  {
                                  id:  '[parameters(\'remoteNetworkId\')]'
                                }
                              }
                            }
                          ]
                        }
                      }
                    }
                  ]
                }  
              }
           }
         }
       }
    }    
  }  
}
