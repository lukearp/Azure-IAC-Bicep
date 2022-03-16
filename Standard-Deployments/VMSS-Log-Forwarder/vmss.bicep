param name string
param location string
param username string
@secure()
param password string
param InstanceSize string
param AutosccaleMin int
param AutosccaleMax int
param BaseName string
param DiskSize int
param OSImage string
param WorkspaceId string
@secure()
param WorkspaceKey string
param subnetId string
param backendPoolId string
param StorageAccountName string
param tags object

var ubuntuServer2004LTSImageSKU = {
  publisher: 'Canonical'
  offer: '0001-com-ubuntu-server-focal'
  sku: '20_04-lts'
  version: 'latest'
}

var ubuntuServer1804LTSImageSKU = {
  publisher: 'Canonical'
  offer: 'UbuntuServer'
  sku: '18.04-LTS'
  version: 'latest'
}

var cloudInit = concat('#cloud-config\nruncmd:\n  - sudo yum update -y\n  - sudo echo "root         soft    nofile         65536" >> /etc/security/limits.conf\n  - sudo echo "root         hard    nofile         65536" >> /etc/security/limits.conf\n  - sudo echo "*         soft    nofile         65536" >> /etc/security/limits.conf\n  - sudo echo "*         hard    nofile         65536" >> /etc/security/limits.conf\n  - sudo apt install python-is-python3\n  - sudo wget https://raw.githubusercontent.com/Azure/Azure-Sentinel/master/DataConnectors/CEF/cef_installer.py\n  - sudo python cef_installer.py ',WorkspaceId,' ',WorkspaceKey,'\n  - sudo wget https://raw.githubusercontent.com/Azure/Azure-Sentinel/master/DataConnectors/CEF-VMSS/security-config-omsagent.conf -O /etc/rsyslog.d/security-config-omsagent.conf\n  - sudo sed -i -e \'\'s@*.*;auth,authpriv.none@syslog.*;auth,authpriv.none@g\'\' /etc/rsyslog.d/50-default.conf\n  - sudo sed -i -e \'\'s@input(type="imudp" port="514")@input(type="imudp" port="514")@g\'\' /etc/rsyslog.conf\n  - sudo sed -i -e \'\'s@input(type="imtcp" port="514")@input(type="imtcp" port="514")@g\'\' /etc/rsyslog.conf\n  - sudo sed -i -e \'\'s@# Use traditional timestamp format.@# Use traditional timestamp format.\\nif $rawmsg contains "CEF:" or $rawmsg contains "ASA-" then \\@\\@127.0.0.1:25226\\n\\& stop@g\'\' /etc/rsyslog.conf\n  - sudo sed -i -e \'\'s@# Where to place spool and state files@if $fromhost-ip != \\x27127.0.0.1\\x27 then stop\\n# Where to place spool and state files@g\'\' /etc/rsyslog.conf\n  - sudo sed -i \'\'s/@127/@@127/g\'\' /etc/rsyslog.d/95-omsagent.conf\n  - sudo systemctl restart rsyslog\n  - sudo sed -i \'\'s/protocol_type udp/protocol_type tcp/g\'\' /etc/opt/microsoft/omsagent/',WorkspaceId,'/conf/omsagent.d/syslog.conf\n  - sudo systemctl restart omsagent-',WorkspaceId)

resource vmss 'Microsoft.Compute/virtualMachineScaleSets@2021-11-01' = {
  location: location
  name: name
  sku: {
    capacity: AutosccaleMin
    tier: 'Standard'
    name: InstanceSize
  }
  zones: [
    '1'
    '2'
    '3'
  ]
  properties: {
    singlePlacementGroup: true
    upgradePolicy: {
      mode: 'Rolling'
      rollingUpgradePolicy: {
        maxBatchInstancePercent: 20
        maxUnhealthyInstancePercent: 20
        maxUnhealthyUpgradedInstancePercent: 20
      }
    }
    virtualMachineProfile: {
      osProfile: {
        computerNamePrefix: BaseName
        adminPassword: password
        adminUsername: username
        linuxConfiguration: {
          disablePasswordAuthentication: false
          provisionVMAgent: true
        }
        customData: base64(cloudInit)   
      }
      storageProfile: {
        osDisk: {
          createOption: 'FromImage'
          caching: 'ReadWrite'
          managedDisk: {
            storageAccountType: 'Premium_LRS'
          }
          diskSizeGB: DiskSize
        }
        imageReference: OSImage == 'UbuntuServer-20.04-LTS' ? ubuntuServer2004LTSImageSKU : ubuntuServer1804LTSImageSKU
      }
      networkProfile: {
        networkInterfaceConfigurations:[
          {
            name: '${BaseName}-NetworkInterface'
            properties: {
              primary: true
              enableAcceleratedNetworking: false
              dnsSettings: {
                dnsServers: []
              }
              enableIPForwarding: false
              ipConfigurations: [
                {
                  name: 'ipconfig'
                  properties: {
                    privateIPAddressVersion: 'IPv4'
                    subnet: {
                      id: subnetId
                    }
                    loadBalancerBackendAddressPools: [
                      {
                        id: backendPoolId 
                      }
                    ]
                  } 
                }
              ]
            } 
          } 
        ] 
      }
      diagnosticsProfile: {
        bootDiagnostics: {
          enabled: true
          storageUri:'https://${StorageAccountName}.blob.core.windows.net'
        }
      }
      extensionProfile: {
        extensions: [
          {
            name: 'VMSS-AppHealth'
            properties: {
              publisher: 'Microsoft.ManagedServices'
              type: 'ApplicationHealthLinux'
              typeHandlerVersion: '1.0'
              autoUpgradeMinorVersion: true
              settings: {
                protocol: 'tcp'
                port: 22
              }
            }
          }
        ]
      }
      priority: 'Regular' 
    }
    zoneBalance: true
    overprovision: true
    platformFaultDomainCount: 5
  } 
  tags: tags  
}

resource autoscale 'Microsoft.Insights/autoscalesettings@2021-05-01-preview' = {
  location: location
  name: '${BaseName}-Autoscale' 
  tags: tags
  properties: {
    profiles: [
      {
       name: 'Profile1'
       capacity: {
         minimum: AutosccaleMin
         maximum: AutosccaleMax
         default: AutosccaleMin
       }
       rules: [
         {
           metricTrigger: {
             metricName: 'Percentage CPU'
             metricNamespace: ''
             metricResourceUri: vmss.id
             timeGrain: 'PT1M'
             statistic: 'Average'
             timeWindow: 'PT5M'
             timeAggregation: 'Average'
             operator: 'GreaterThan'
             threshold: 75
             dimensions: [
               
             ] 
             dividePerInstance: false
           }
           scaleAction: {
             direction: 'Increase'
             type: 'ChangeCount'
             value: '1'
             cooldown: 'PT1M'
           }
         }
         {
          metricTrigger: {
            metricName: 'Percentage CPU'
            metricNamespace: ''
            metricResourceUri: vmss.id
            timeGrain: 'PT1M'
            statistic: 'Average'
            timeWindow: 'PT5M'
            timeAggregation: 'Average'
            operator: 'LessThan'
            threshold: 25
            dimensions: [
              
            ] 
            dividePerInstance: false
          }
          scaleAction: {
            direction: 'Decrease'
            type: 'ChangeCount'
            value: '1'
            cooldown: 'PT1M'
          }
        }
       ]
      }
    ]
    enabled: true
    name: '${BaseName}-Autoscale'
    targetResourceUri: vmss.id    
  }  
}
