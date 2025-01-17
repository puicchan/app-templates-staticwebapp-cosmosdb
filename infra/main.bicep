targetScope = 'subscription'

@minLength(1)
@maxLength(16)
@description('Prefix for all resources, i.e. {name}storage')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
// param location string = deployment().location
param location string

var tags = { 'azd-env-name': environmentName }

resource rg 'Microsoft.Resources/resourceGroups@2020-06-01' = {
  name: '${environmentName}-rg'
  location: location
  tags: tags
}

module storage './resources/storage.bicep' = {
  name: '${rg.name}-storage'
  scope: rg
  params: {
    nameprefix: toLower(environmentName)
    location: rg.location
  }
}

module function './resources/function.bicep' = {
  name: '${rg.name}-function'
  scope: rg
  params: {
    nameprefix: toLower(environmentName)
    location: rg.location
    serviceName: 'api'
  }
  dependsOn: [
    // We need to insert the Cosmos ConnectionString in the function's parameters so it needs to exist first
    cosmosdb
  ]
}

module frontdoor './resources/frontdoor.bicep' = {
  name: '${rg.name}-frontdoor'
  scope: rg
  params: {
    nameprefix: toLower(environmentName)
    apiUrl: function.outputs.functionUrl
    webUrl: storage.outputs.staticWebsiteUrl
  }
}

module cosmosdb './resources/cosmosdb.bicep' = {
  name: '${rg.name}-cosmosdb'
  scope: rg
  params: {
    nameprefix: toLower(environmentName)
    location: rg.location
  }
}

output resource_group_name string = rg.name
output function_name string = function.outputs.functionName
output storage_account_name string = storage.outputs.storageAccountName
output cosmosdb_name string = cosmosdb.outputs.cosmosDBName
output frontdoor_hostname string = frontdoor.outputs.frontDoorEndpointHostName
