/**
 * @module passthrough-api
 * @description This module defines the API resources using Terraform.
 * It includes configurations for creating and managing APIs, products, and policies.
 * This is version 2 (v2) of the Passthrough API Terraform module.
 */

# ------------------
#    VARIABLES
# ------------------

variable "api_management_name" {
  description = "The name of the API Management instance"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "apim_logger_id" {
  description = "Id of the APIM Logger"
  type        = string
  default     = ""
}

variable "app_insights_id" {
  description = "The resource ID for Application Insights"
  type        = string
  default     = ""
}

variable "app_insights_instrumentation_key" {
  description = "The instrumentation key for Application Insights"
  type        = string
  default     = ""
  sensitive   = true
}

variable "policy_xml" {
  description = "The XML content for the API policy"
  type        = string
}

variable "passthrough_services_config" {
  description = "Configuration array for passthrough services"
  type = list(object({
    name           = string
    endpoint       = string
    authHeaderName = string
    authKey        = string
  }))
  default = []
}

variable "passthrough_api_name" {
  description = "The name of the passthrough API in API Management"
  type        = string
  default     = "passthrough-api"
}

variable "passthrough_api_description" {
  description = "The description of the passthrough API in API Management"
  type        = string
  default     = "Passthrough API"
}

variable "passthrough_api_display_name" {
  description = "The display name of the passthrough API in API Management"
  type        = string
  default     = "Passthrough API"
}

variable "passthrough_backend_pool_name" {
  description = "The name of the passthrough backend pool"
  type        = string
}

variable "passthrough_api_type" {
  description = "The passthrough API type"
  type        = string
  default     = "ServiceNow"
  validation {
    condition     = contains(["ServiceNow", "Cognigy"], var.passthrough_api_type)
    error_message = "The passthrough_api_type must be one of: ServiceNow, Cognigy"
  }
}

variable "passthrough_api_path" {
  description = "The path to the passthrough API in the APIM service"
  type        = string
  default     = "passthrough"
}

variable "configure_circuit_breaker" {
  description = "Whether to configure the circuit breaker for the passthrough backend"
  type        = bool
  default     = true
}

# ------------------
#    LOCALS
# ------------------

locals {
  log_settings = {
    headers = ["Content-type", "User-agent", "x-ms-region", "x-ratelimit-remaining-tokens", "x-ratelimit-remaining-requests"]
    body_bytes = 8192
  }

  updated_policy_xml = replace(var.policy_xml, "{backend-id}", var.passthrough_backend_pool_name)

  endpoint_path = var.passthrough_api_type == "ServiceNow" ? "servicenow" : (var.passthrough_api_type == "Cognigy" ? "cognigy" : "")
  
  openapi_spec = file("${path.module}/specs/PassThrough.json")
}

# ------------------
#    RESOURCES
# ------------------

data "azurerm_api_management" "apim" {
  name                = var.api_management_name
  resource_group_name = var.resource_group_name
}

resource "azurerm_api_management_api" "passthrough_api" {
  name                  = var.passthrough_api_name
  resource_group_name   = var.resource_group_name
  api_management_name   = var.api_management_name
  revision              = "1"
  display_name          = var.passthrough_api_display_name
  path                  = "${var.passthrough_api_path}/${local.endpoint_path}"
  protocols             = ["https"]
  subscription_required = false
  description           = var.passthrough_api_description

  import {
    content_format = "openapi+json"
    content_value  = local.openapi_spec
  }

  subscription_key_parameter_names {
    header = "api-key"
    query  = "api-key"
  }
}

resource "azurerm_api_management_api_policy" "passthrough_policy" {
  api_name            = azurerm_api_management_api.passthrough_api.name
  api_management_name = var.api_management_name
  resource_group_name = var.resource_group_name

  xml_content = local.updated_policy_xml

  depends_on = [azurerm_api_management_backend.passthrough_backend]
}

resource "azurerm_api_management_named_value" "auth_keys" {
  for_each = { for config in var.passthrough_services_config : config.name => config }

  name                = "passthrough-backend-authkey-${each.key}"
  resource_group_name = var.resource_group_name
  api_management_name = var.api_management_name
  display_name        = "Passthrough-Backend-Auth-Key-${each.key}"
  value               = each.value.authKey
  secret              = true
}

resource "azurerm_api_management_backend" "passthrough_backend" {
  for_each = { for config in var.passthrough_services_config : config.name => config }

  name                = each.key
  resource_group_name = var.resource_group_name
  api_management_name = var.api_management_name
  protocol            = "http"
  url                 = each.value.endpoint
  description         = "passthrough backend"

  credentials {
    header = {
      "${each.value.authHeaderName}" = "{{passthrough-backend-authkey-${each.key}}}"
    }
  }

  # Note: Circuit breaker configuration is not directly supported in azurerm provider
  # This would need to be configured via ARM template or REST API

  depends_on = [azurerm_api_management_named_value.auth_keys]
}

resource "azurerm_api_management_api_diagnostic" "azure_monitor" {
  count                    = var.apim_logger_id != "" ? 1 : 0
  identifier               = "azuremonitor"
  resource_group_name      = var.resource_group_name
  api_management_name      = var.api_management_name
  api_name                 = azurerm_api_management_api.passthrough_api.name
  api_management_logger_id = var.apim_logger_id

  sampling_percentage       = 100.0
  always_log_errors         = true
  log_client_ip             = true
  verbosity                 = "verbose"
  http_correlation_protocol = "W3C"

  frontend_request {
    body_bytes     = 0
    headers_to_log = []
  }

  frontend_response {
    body_bytes     = 0
    headers_to_log = []
  }

  backend_request {
    body_bytes     = 0
    headers_to_log = []
  }

  backend_response {
    body_bytes     = 0
    headers_to_log = []
  }
}

resource "azurerm_api_management_api_diagnostic" "app_insights" {
  count                    = var.app_insights_id != "" && var.app_insights_instrumentation_key != "" ? 1 : 0
  identifier               = "applicationinsights"
  resource_group_name      = var.resource_group_name
  api_management_name      = var.api_management_name
  api_name                 = azurerm_api_management_api.passthrough_api.name
  api_management_logger_id = "${data.azurerm_api_management.apim.id}/loggers/appinsights-logger"

  sampling_percentage       = 100.0
  always_log_errors         = true
  log_client_ip             = true
  verbosity                 = "verbose"
  http_correlation_protocol = "W3C"

  frontend_request {
    body_bytes     = local.log_settings.body_bytes
    headers_to_log = local.log_settings.headers
  }

  frontend_response {
    body_bytes     = local.log_settings.body_bytes
    headers_to_log = local.log_settings.headers
  }

  backend_request {
    body_bytes     = local.log_settings.body_bytes
    headers_to_log = local.log_settings.headers
  }

  backend_response {
    body_bytes     = local.log_settings.body_bytes
    headers_to_log = local.log_settings.headers
  }
}

# ------------------
#    OUTPUTS
# ------------------

output "api_id" {
  description = "The ID of the passthrough API"
  value       = azurerm_api_management_api.passthrough_api.id
}
