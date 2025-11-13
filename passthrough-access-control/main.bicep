// ------------------
//    PARAMETERS
// ------------------


param apimSku string
param apimSubscriptionsConfig array = []
param tenantId string
param clientId string

@description('The URL of the passthrough backend API.')
@allowed([
  'ServiceNow'
  'Cognigy'
]
)
param passthroughApiType string = 'ServiceNow'
param passthroughApi string 
param authHeaderName string
@secure()
param authKey string


// ------------------
//    RESOURCES
// ------------------

// 1. Log Analytics Workspace
module lawModule '../modules/operational-insights/v1/workspaces.bicep' = {
  name: 'lawModule'
}

// 2. Application Insights
module appInsightsModule '../modules/monitor/v1/appinsights.bicep' = {
  name: 'appInsightsModule'
  params: {
    lawId: lawModule.outputs.id
    customMetricsOptedInType: 'WithDimensions'
  }
}

// 3. API Management
module apimModule '../modules/apim/v2/apim.bicep' = {
  name: 'apimModule'
  params: {
    apimSku: apimSku
    apimSubscriptionsConfig: apimSubscriptionsConfig
    lawId: lawModule.outputs.id
    appInsightsId: appInsightsModule.outputs.id
    appInsightsInstrumentationKey: appInsightsModule.outputs.instrumentationKey
  }
}


// 5. APIM passthrough API
module passthroughAPIModule '../modules/apim/v2/passthrough-api.bicep' = {
  name: 'passthroughAPIModule'
  params: {
    policyXml: replace(replace(replace(loadTextContent('policy.xml'), '{tenant-id}', tenantId), '{client-application-id}', clientId), '{api-type}', passthroughApiType)
    apimLoggerId: apimModule.outputs.loggerId
    appInsightsId: appInsightsModule.outputs.id
    appInsightsInstrumentationKey: appInsightsModule.outputs.instrumentationKey
    apiManagementName: apimModule.outputs.name
    passthroughBackendPoolName: passthroughApiType
    passthroughAPIName: 'passthrough-api'
    passthroughAPIDescription: 'ServiceNow Passthrough API'
    passthroughAPIDisplayName: 'ServiceNow Passthrough API'
    passthroughServicesConfig: [{
      name: passthroughApiType
      endpoint: passthroughApi
      authHeaderName: authHeaderName
      authKey: authKey
    }]
    passthroughAPIType: passthroughApiType
    passthroughAPIPath: 'passthrough'
  }
}


// ------------------
//    OUTPUTS
// ------------------

output logAnalyticsWorkspaceId string = lawModule.outputs.customerId
output apimServiceId string = apimModule.outputs.id
output apimResourceGatewayURL string = apimModule.outputs.gatewayUrl

output apimSubscriptions array = apimModule.outputs.apimSubscriptions



