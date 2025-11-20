/**
 * Example Terraform configuration showing how to use the modules
 * This is equivalent to the main.bicep in the parent directory
 */

terraform {
  required_version = ">= 1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# ------------------
#    VARIABLES
# ------------------

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "swedencentral"
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "demo-passthrough-access-control"
}

variable "apim_sku" {
  description = "APIM SKU"
  type        = string
  default     = "Standardv2"
}

variable "passthrough_backend_url" {
  description = "Passthrough backend URL"
  type        = string
}

variable "passthrough_api_type" {
  description = "Passthrough API type"
  type        = string
  default     = "ServiceNow"
}

variable "auth_header_name" {
  description = "Authentication header name"
  type        = string
  default     = "X-Api-Key"
}

variable "auth_key" {
  description = "Authentication key"
  type        = string
  sensitive   = true
}

variable "apim_subscriptions_config" {
  description = "APIM subscriptions configuration"
  type = list(object({
    name        = string
    displayName = string
  }))
  default = []
}

variable "tenant_id" {
  description = "Azure AD Tenant ID"
  type        = string
}

variable "client_id" {
  description = "Client ID for app registration"
  type        = string
}

# ------------------
#    LOCALS
# ------------------

locals {
  resource_suffix = substr(md5(data.azurerm_subscription.current.id), 0, 8)
}

# ------------------
#    DATA SOURCES
# ------------------

data "azurerm_subscription" "current" {}

data "azurerm_client_config" "current" {}

# ------------------
#    RESOURCES
# ------------------

resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
}

# Log Analytics Workspace
module "log_analytics" {
  source = "./modules/operational-insights/v1"

  resource_group_name    = azurerm_resource_group.main.name
  log_analytics_location = azurerm_resource_group.main.location
  resource_suffix        = local.resource_suffix
}

# Application Insights
module "app_insights" {
  source = "./modules/monitor/v1"

  resource_group_name           = azurerm_resource_group.main.name
  application_insights_location = azurerm_resource_group.main.location
  resource_suffix               = local.resource_suffix
  law_id                        = module.log_analytics.id
  workbook_location             = azurerm_resource_group.main.location
}

# API Management
module "apim" {
  source = "./modules/apim/v2"

  resource_group_name              = azurerm_resource_group.main.name
  location                         = azurerm_resource_group.main.location
  resource_suffix                  = local.resource_suffix
  apim_sku                         = var.apim_sku
  law_id                           = module.log_analytics.id
  app_insights_id                  = module.app_insights.id
  app_insights_instrumentation_key = module.app_insights.instrumentation_key
  apim_subscriptions_config        = var.apim_subscriptions_config
}

# Passthrough API (Note: This would need policy_xml content)
# Uncomment and configure when policy XML is available
# module "passthrough_api" {
#   source = "./modules/apim/v2"
#   
#   api_management_name     = module.apim.name
#   resource_group_name     = azurerm_resource_group.main.name
#   apim_logger_id          = module.apim.logger_id
#   app_insights_id         = module.app_insights.id
#   app_insights_instrumentation_key = module.app_insights.instrumentation_key
#   
#   policy_xml = file("${path.module}/policy.xml")
#   
#   passthrough_backend_pool_name = "passthrough-pool"
#   passthrough_api_type          = var.passthrough_api_type
#   
#   passthrough_services_config = [
#     {
#       name           = "passthrough-backend"
#       endpoint       = var.passthrough_backend_url
#       authHeaderName = var.auth_header_name
#       authKey        = var.auth_key
#     }
#   ]
# }

# ------------------
#    OUTPUTS
# ------------------

output "resource_group_name" {
  description = "The name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID"
  value       = module.log_analytics.id
}

output "apim_service_id" {
  description = "APIM Service ID"
  value       = module.apim.id
}

output "apim_gateway_url" {
  description = "APIM Gateway URL"
  value       = module.apim.gateway_url
}

output "apim_subscriptions" {
  description = "APIM Subscriptions"
  value       = module.apim.apim_subscriptions
  sensitive   = true
}
