param vmName string
param adminUsername string
@secure()
param adminPassword string
param location string = resourceGroup().location
param dataDisks array = []
param image object
param networkInterfaces array
param tags object = {}
