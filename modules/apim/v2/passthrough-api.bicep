/**
 * @module 
 * @description This module defines the API resources using Bicep.
 * It includes configurations for creating and managing APIs, products, and policies.
 * This is version 2 (v2) of the APIM Bicep module.
 */

// ------------------
//    PARAMETERS
// ------------------

@description('The suffix to append to the API Management instance name. Defaults to a unique string based on subscription and resource group IDs.')
param resourceSuffix string = uniqueString(subscription().id, resourceGroup().id)

@description('The name of the API Management instance. Defaults to "apim-<resourceSuffix>".')
param apiManagementName string = 'apim-${resourceSuffix}'

@description('Id of the APIM Logger')
param apimLoggerId string = ''

@description('The instrumentation key for Application Insights')
@secure()
param appInsightsInstrumentationKey string = ''

@description('The resource ID for Application Insights')
param appInsightsId string = ''

@description('The XML content for the API policy')
param policyXml string

@description('Configuration array for AI Services')
param passthroughServicesConfig array = []

@description('The name of the passthrough API in API Management.')
param passthroughAPIName string = 'passthrough-api'

@description('The description of the passthrough API in API Management.')
param passthroughAPIDescription string = 'Passthrough API'

@description('The display name of the passthrough API in API Management. .')
param passthroughAPIDisplayName string = 'Passthrough API'

@description('The name of the passthrough backend pool.')
param passthroughBackendPoolName string

@description('The passthrough API type')
@allowed([
  'ServiceNow'
  'Cognigy'
])
param passthroughAPIType string = 'ServiceNow'

@description('The path to the passthrough API in the APIM service')
param passthroughAPIPath string = 'passthrough' // Path to the passthrough API in the APIM service

@description('Whether to configure the circuit breaker for the passthrough backend')
param configureCircuitBreaker bool = true

// ------------------
//    VARIABLES
// ------------------

var logSettings = {
  headers: [ 'Content-type', 'User-agent', 'x-ms-region', 'x-ratelimit-remaining-tokens' , 'x-ratelimit-remaining-requests' ]
  body: { bytes: 8192 }
}

var updatedPolicyXml = replace(policyXml, '{backend-id}', passthroughBackendPoolName)

// ------------------
//    RESOURCES
// ------------------

resource apimService 'Microsoft.ApiManagement/service@2024-06-01-preview' existing = {
  name: apiManagementName
}

var endpointPath = (passthroughAPIType == 'ServiceNow') ? 'servicenow' : (passthroughAPIType == 'Cognigy') ? 'cognigy' : ''

// https://learn.microsoft.com/azure/templates/microsoft.apimanagement/service/apis
resource api 'Microsoft.ApiManagement/service/apis@2024-06-01-preview' = {
  name: passthroughAPIName
  parent: apimService
  properties: {
    apiType: 'http'
    description: passthroughAPIDescription
    displayName: passthroughAPIDisplayName
    format: 'openapi+json'
    path: '${passthroughAPIPath}/${endpointPath}'
    protocols: [
      'https'
    ]
    subscriptionKeyParameterNames: {
      header: 'api-key'
      query: 'api-key'
    }
    subscriptionRequired: false
    type: 'http'
    value: string(loadJsonContent('./specs/PassThrough.json'))
  }
}
// https://learn.microsoft.com/azure/templates/microsoft.apimanagement/service/apis/policies
resource apiPolicy 'Microsoft.ApiManagement/service/apis/policies@2024-06-01-preview' = {
  name: 'policy'
  parent: api
  properties: {
    format: 'rawxml'
    value: updatedPolicyXml
  }
  dependsOn: [
    passthroughBackend
  ]
} 

resource namedValues 'Microsoft.ApiManagement/service/namedValues@2024-10-01-preview' = [for (config, i) in passthroughServicesConfig: if(length(passthroughServicesConfig) > 0) {
  name: 'passthrough-backend-authkey-${config.name}'
  parent: apimService
  properties: {
    displayName: 'Passthrough-Backend-Auth-Key-${config.name}'
    value: config.authKey
    secret: true
  }
}]

// https://learn.microsoft.com/azure/templates/microsoft.apimanagement/service/backends
resource passthroughBackend 'Microsoft.ApiManagement/service/backends@2024-10-01-preview' =  [for (config, i) in passthroughServicesConfig: if(length(passthroughServicesConfig) > 0) {
  name: config.name
  parent: apimService
  properties: {
    description: 'passthrough backend'
    url: '${config.endpoint}'
    protocol: 'http'
    circuitBreaker: (configureCircuitBreaker) ? {
      rules: [
      {
        failureCondition: {
        count: 1
        errorReasons: [
          'Server errors'
        ]
        interval: 'PT5M'
        statusCodeRanges: [
          {
          min: 429
          max: 429
          }
        ]
        }
        name: 'passthroughBreakerRule'
        tripDuration: 'PT1M'
        acceptRetryAfter: true
      }
      ]
    }: null
    credentials: {
     header:{
        '${config.authHeaderName}': [
            '{{passthrough-backend-authkey-${config.name}}}'
        ]
     }
    }
  }
  dependsOn: [
    namedValues
  ]
}] 


resource apiDiagnostics 'Microsoft.ApiManagement/service/apis/diagnostics@2024-06-01-preview' = if(length(apimLoggerId) > 0) {
  parent: api
  name: 'azuremonitor'
  properties: {
    alwaysLog: 'allErrors'
    verbosity: 'verbose'
    logClientIp: true
    loggerId: apimLoggerId
    sampling: {
      samplingType: 'fixed'
      percentage: json('100')
    }
    frontend: {
      request: {
        headers: []
        body: {
          bytes: 0
        }
      }
      response: {
        headers: []
        body: {
          bytes: 0
        }
      }
    }
    backend: {
      request: {
        headers: []
        body: {
          bytes: 0
        }
      }
      response: {
        headers: []
        body: {
          bytes: 0
        }
      }
    }
    largeLanguageModel: {
      logs: 'enabled'
      requests: {
        messages: 'all'
        maxSizeInBytes: 262144
      }
      responses: {
        messages: 'all'
        maxSizeInBytes: 262144
      }
    }
  }
} 

resource apiDiagnosticsAppInsights 'Microsoft.ApiManagement/service/apis/diagnostics@2022-08-01' = if (!empty(appInsightsId) && !empty(appInsightsInstrumentationKey)) {
  name: 'applicationinsights'
  parent: api
  properties: {
    alwaysLog: 'allErrors'
    httpCorrelationProtocol: 'W3C'
    logClientIp: true
    loggerId: resourceId(resourceGroup().name, 'Microsoft.ApiManagement/service/loggers', apiManagementName, 'appinsights-logger')
    metrics: true
    verbosity: 'verbose'
    sampling: {
      samplingType: 'fixed'
      percentage: 100
    }
    frontend: {
      request: logSettings
      response: logSettings
    }
    backend: {
      request: logSettings
      response: logSettings
    }
  }
}

// ------------------
//    OUTPUTS
// ------------------

output apiId string = api.id  
