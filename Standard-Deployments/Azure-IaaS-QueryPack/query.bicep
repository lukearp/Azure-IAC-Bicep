param querypacks_IaaS_Monitoring_name string = 'IaaS-Monitoring'
param location string = ''

resource querypacks_IaaS_Monitoring_name_resource 'Microsoft.OperationalInsights/querypacks@2019-09-01' = {
  name: querypacks_IaaS_Monitoring_name
  location: location
  tags: {
    Environment: 'Prod'
  }
  properties: {
  }
}

resource querypacks_IaaS_Monitoring_name_0636cfa7_0d7c_4a5a_b32f_488451649c52 'Microsoft.OperationalInsights/querypacks/queries@2019-09-01' = {
  parent: querypacks_IaaS_Monitoring_name_resource
  name: '0636cfa7-0d7c-4a5a-b32f-488451649c52'
  properties: {
    displayName: 'Failed Logins'
    body: 'SecurityEvent \r\n| where Channel == "Security" and Account !contains "\\\\SYSTEM" and Account !contains "$" and Account != "" and EventID == 4625\r\n| where Account contains "NETBIOS\\\\"\r\n| sort by TimeGenerated desc'
    related: {
      categories: [
        'audit'
      ]
      resourceTypes: [
        'microsoft.operationalinsights/workspaces'
      ]
    }
    tags: {
      labels: []
    }
  }
}

resource querypacks_IaaS_Monitoring_name_0efa0098_03f2_4594_ab69_941637ee5011 'Microsoft.OperationalInsights/querypacks/queries@2019-09-01' = {
  parent: querypacks_IaaS_Monitoring_name_resource
  name: '0efa0098-03f2-4594-ab69-941637ee5011'
  properties: {
    displayName: 'Privileged Group Add and Remove'
    body: 'SecurityEvent\r\n| where Channel == "Security" and (EventID == 4728 or EventID == 4732 or EventID == 4756 or EventID == 4761 or EventID == 4751 or EventID == 4729 or EventID == 4733 or EventID == 4757 or EventID == 4762 or EventID == 4747 or EventID == 4752)\r\n| sort by TimeGenerated desc \r\n| extend Action=iff((EventID == 4728 or EventID == 4732 or EventID == 4756 or EventID == 4761 or EventID == 4751),"Add","Remove")\r\n| project User=Account, Action ,TimeGenerated, DC=Computer, Group=TargetAccount, EventData'
    related: {
      categories: [
        'audit'
      ]
      resourceTypes: [
        'microsoft.operationalinsights/workspaces'
      ]
    }
    tags: {
      labels: []
    }
  }
}

resource querypacks_IaaS_Monitoring_name_2d144d08_c65c_5d5c_8a59_b683a36b6fc2 'Microsoft.OperationalInsights/querypacks/queries@2019-09-01' = {
  parent: querypacks_IaaS_Monitoring_name_resource
  name: '2d144d08-c65c-5d5c-8a59-b683a36b6fc2'
  properties: {
    displayName: 'Memory Average over 95 Percent'
    body: 'InsightsMetrics\r\n| where Namespace == "Memory" and TimeGenerated > ago(5m)\r\n| project Computer,  Percentage=100 - (Val / parse_json(Tags)["vm.azm.ms/memorySizeMB"] * 100)\r\n| summarize avg(Percentage) by Computer\r\n| where avg_Percentage > 95'
    related: {
      categories: [
        'virtualmachines'
      ]
      resourceTypes: [
        'microsoft.operationalinsights/workspaces'
      ]
    }
    tags: {
      labels: [
        'Performance'
      ]
    }
  }
}

resource querypacks_IaaS_Monitoring_name_46e59537_0680_41f8_9d14_3804e082ac75 'Microsoft.OperationalInsights/querypacks/queries@2019-09-01' = {
  parent: querypacks_IaaS_Monitoring_name_resource
  name: '46e59537-0680-41f8-9d14-3804e082ac75'
  properties: {
    displayName: 'MS SQL DB Offline'
    body: 'Event\r\n| where EventLog == "Application" and RenderedDescription contains "Offline to ON"\r\n| where EventID == 5084\r\n| extend ConfiguredMessage=strcat(split(RenderedDescription,\'\\\'\',1)[0], \' DB has went offline.\') \r\n| project ConfiguredMessage, TimeGenerated, Computer'
    related: {
      categories: [
        'databases'
      ]
      resourceTypes: [
        'microsoft.operationalinsights/workspaces'
      ]
    }
    tags: {
      labels: []
    }
  }
}

resource querypacks_IaaS_Monitoring_name_57b29bf9_1183_5a00_a5be_ccef3be0aa78 'Microsoft.OperationalInsights/querypacks/queries@2019-09-01' = {
  parent: querypacks_IaaS_Monitoring_name_resource
  name: '57b29bf9-1183-5a00-a5be-ccef3be0aa78'
  properties: {
    displayName: 'Server Down'
    body: 'Heartbeat \r\n| summarize LastCall = max(TimeGenerated) by Computer \r\n| where LastCall < ago(5m)'
    related: {
      categories: [
        'virtualmachines'
      ]
      resourceTypes: [
        'microsoft.operationalinsights/workspaces'
      ]
    }
    tags: {
      labels: [
        'Availability'
      ]
    }
  }
}

resource querypacks_IaaS_Monitoring_name_5ba8eefc_77ad_4e6a_8dc9_ed32d592f630 'Microsoft.OperationalInsights/querypacks/queries@2019-09-01' = {
  parent: querypacks_IaaS_Monitoring_name_resource
  name: '5ba8eefc-77ad-4e6a-8dc9-ed32d592f630'
  properties: {
    displayName: 'User Account Disabled'
    body: 'SecurityEvent \r\n| where Channel == "Security" and Account !contains "\\\\SYSTEM" and Account !contains "$" and Account != "" and EventID == 4725\r\n| where Account contains "NETBIOSNAME\\\\"\r\n| sort by TimeGenerated desc'
    related: {
      categories: [
        'audit'
      ]
      resourceTypes: [
        'microsoft.operationalinsights/workspaces'
      ]
    }
    tags: {
      labels: []
    }
  }
}

resource querypacks_IaaS_Monitoring_name_66dbf1ee_ed5e_4cc5_a86c_a33c7604c6a5 'Microsoft.OperationalInsights/querypacks/queries@2019-09-01' = {
  parent: querypacks_IaaS_Monitoring_name_resource
  name: '66dbf1ee-ed5e-4cc5-a86c-a33c7604c6a5'
  properties: {
    displayName: 'Hyper-V VM Fail'
    body: 'Event\r\n| where EventLog contains "System" and (EventID == 1069 or EventID == 1205) and ParameterXml contains "Virtual Machine" // 1069 = Failed State or EventID == 1205 = Unable to Recover)\r\n| sort by TimeGenerated desc  \r\n| project HyperV_Host=Computer, VM=split(split(ParameterXml,\'<Param>Virtual Machine\')[1],\'</Param>\')[0], RenderedDescription,TimeGenerated'
    related: {
      categories: [
        'virtualmachines'
      ]
      resourceTypes: [
        'microsoft.operationalinsights/workspaces'
      ]
    }
    tags: {
      labels: []
    }
  }
}

resource querypacks_IaaS_Monitoring_name_71aca15c_7a86_4461_ba10_91893e9c40b7 'Microsoft.OperationalInsights/querypacks/queries@2019-09-01' = {
  parent: querypacks_IaaS_Monitoring_name_resource
  name: '71aca15c-7a86-4461-ba10-91893e9c40b7'
  properties: {
    displayName: 'Bandwidth-By-Machine'
    body: 'VMConnection\r\n| where TimeGenerated > ago(2h) and RemoteIp != "127.0.0.1"\r\n| project Computer, RemoteIp, Direction,Total=BytesSent+BytesReceived, TimeGenerated\r\n| summarize avg(Total) by Computer,RemoteIp\r\n| extend AvgMB=avg_Total/1000000, AvgBytes=avg_Total\r\n| project Computer, RemoteIp, AvgMB, AvgBytes\r\n| sort by AvgMB desc '
    related: {
      categories: [
        'virtualmachines'
      ]
      resourceTypes: [
        'microsoft.operationalinsights/workspaces'
      ]
    }
    tags: {
      labels: []
    }
  }
}

resource querypacks_IaaS_Monitoring_name_82fc0996_0d19_42b8_a9c4_b13b764a6130 'Microsoft.OperationalInsights/querypacks/queries@2019-09-01' = {
  parent: querypacks_IaaS_Monitoring_name_resource
  name: '82fc0996-0d19-42b8-a9c4-b13b764a6130'
  properties: {
    displayName: 'MS SQL DB State Change'
    body: 'Event\r\n| where EventLog == "Application" and Source == "MSSQLSERVER" and RenderedDescription contains "Online to ON" or RenderedDescription contains "Offline to ON"\r\n| where EventID == 5084'
    related: {
      categories: [
        'databases'
      ]
      resourceTypes: [
        'microsoft.operationalinsights/workspaces'
      ]
    }
    tags: {
      labels: []
    }
  }
}

resource querypacks_IaaS_Monitoring_name_8c6d9e64_ee45_43d3_84c4_c49eb6bcbd5d 'Microsoft.OperationalInsights/querypacks/queries@2019-09-01' = {
  parent: querypacks_IaaS_Monitoring_name_resource
  name: '8c6d9e64-ee45-43d3-84c4-c49eb6bcbd5d'
  properties: {
    displayName: 'Hard Drive Percentage Used'
    body: 'let freeGB = InsightsMetrics\r\n| where Namespace == "LogicalDisk" and Name == "FreeSpaceMB"\r\n| summarize avg(Val) by Computer, Tags \r\n| project Computer,Disk=parse_json(Tags)["vm.azm.ms/mountId"], Freespace=todecimal(avg_Val / 1000), DiskSize=todecimal(parse_json(Tags)["vm.azm.ms/diskSizeMB"]) / 1000\r\n| extend UsedPercentage=toint(100 - (Freespace/DiskSize * 100)), UsedGB=toint(DiskSize-Freespace);\r\nfreeGB\r\n| where Freespace < 100 and UsedPercentage > 95'
    related: {
      categories: [
        'virtualmachines'
      ]
      resourceTypes: [
        'microsoft.operationalinsights/workspaces'
      ]
    }
    tags: {
      labels: []
    }
  }
}

resource querypacks_IaaS_Monitoring_name_9352bb15_ee05_4c1d_ab41_1e16dd6a00b1 'Microsoft.OperationalInsights/querypacks/queries@2019-09-01' = {
  parent: querypacks_IaaS_Monitoring_name_resource
  name: '9352bb15-ee05-4c1d-ab41-1e16dd6a00b1'
  properties: {
    displayName: 'User Login'
    body: 'SecurityEvent \r\n| where Channel == "Security" and Account !contains "\\\\SYSTEM" and Account !contains "$" and Account != "" and EventID == 4624\r\n| where Account contains "NETBIOSNAME\\\\" \r\n| sort by TimeGenerated desc'
    related: {
      categories: [
        'audit'
      ]
      resourceTypes: [
        'microsoft.operationalinsights/workspaces'
      ]
    }
    tags: {
      labels: []
    }
  }
}

resource querypacks_IaaS_Monitoring_name_9d330b5a_09dd_590c_841a_dd560a548e86 'Microsoft.OperationalInsights/querypacks/queries@2019-09-01' = {
  parent: querypacks_IaaS_Monitoring_name_resource
  name: '9d330b5a-09dd-590c-841a-dd560a548e86'
  properties: {
    displayName: 'CPU over 95 Percent'
    body: 'InsightsMetrics \r\n//| where Namespace == "Processor" and Name == "UtilizationPercentage" and TimeGenerated > ago(10m)\r\n| summarize avg(Val) by Computer\r\n| where avg_Val > 95'
    related: {
      categories: [
        'virtualmachines'
      ]
      resourceTypes: [
        'microsoft.operationalinsights/workspaces'
      ]
    }
    tags: {
      labels: [
        'Performance'
      ]
    }
  }
}

resource querypacks_IaaS_Monitoring_name_b551628e_ece1_47ab_9dfe_f46c71b585ff 'Microsoft.OperationalInsights/querypacks/queries@2019-09-01' = {
  parent: querypacks_IaaS_Monitoring_name_resource
  name: 'b551628e-ece1-47ab-9dfe-f46c71b585ff'
  properties: {
    displayName: 'Defender Updates Needed'
    body: 'Update\r\n| where Product contains "Defender" and UpdateState != "Installed"\r\n| project Computer, TimeGenerated, Product, UpdateState'
    related: {
      categories: [
        'virtualmachines'
      ]
      resourceTypes: [
        'microsoft.operationalinsights/workspaces'
      ]
    }
    tags: {
      labels: []
    }
  }
}

resource querypacks_IaaS_Monitoring_name_deb7f344_bae0_4c15_980b_ea1a7459991e 'Microsoft.OperationalInsights/querypacks/queries@2019-09-01' = {
  parent: querypacks_IaaS_Monitoring_name_resource
  name: 'deb7f344-bae0-4c15-980b-ea1a7459991e'
  properties: {
    displayName: 'New Installed Software'
    body: 'Event\r\n| where EventLog == "Application" and EventID == 11707 and UserName != "NT AUTHORITY\\\\SYSTEM"\r\n| project Computer, RenderedDescription, TimeGenerated, UserName\r\n| sort by TimeGenerated'
    related: {
      categories: [
        'virtualmachines'
      ]
      resourceTypes: [
        'microsoft.operationalinsights/workspaces'
      ]
    }
    tags: {
      labels: []
    }
  }
}

resource querypacks_IaaS_Monitoring_name_e5a39c35_d4ab_44ab_9a32_b035e0523878 'Microsoft.OperationalInsights/querypacks/queries@2019-09-01' = {
  parent: querypacks_IaaS_Monitoring_name_resource
  name: 'e5a39c35-d4ab-44ab-9a32-b035e0523878'
  properties: {
    displayName: 'New Device Attached'
    body: 'SecurityEvent | where Channel == "Security" and EventID == 6416 and ClassName != "PrintQueue"\r\n| sort by TimeGenerated desc'
    related: {
      categories: [
        'virtualmachines'
      ]
      resourceTypes: [
        'microsoft.operationalinsights/workspaces'
      ]
    }
    tags: {
      labels: []
    }
  }
}
