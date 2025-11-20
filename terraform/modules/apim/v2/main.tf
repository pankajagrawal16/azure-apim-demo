/**
 * @module apim-v2
 * @description This module defines the Azure API Management (APIM) resources using Terraform.
 * It includes configurations for creating and managing APIM instance.
 * This is version 2 (v2) of the APIM Terraform module.
 */

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

# ------------------
#    VARIABLES
# ------------------

variable "resource_suffix" {
  description = "The suffix to append to the API Management instance name"
  type        = string
  default     = ""
}

variable "api_management_name" {
  description = "The name of the API Management instance"
  type        = string
  default     = ""
}

variable "location" {
  description = "The location of the API Management instance"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "publisher_email" {
  description = "The email address of the publisher"
  type        = string
  default     = "noreply@microsoft.com"
}

variable "publisher_name" {
  description = "The name of the publisher"
  type        = string
  default     = "Microsoft"
}

variable "apim_sku" {
  description = "The pricing tier of this API Management service"
  type        = string
  default     = "Basicv2"
  validation {
    condition     = contains(["Consumption", "Developer", "Basic", "Basicv2", "Standard", "Standardv2", "Premium"], var.apim_sku)
    error_message = "The apim_sku must be one of: Consumption, Developer, Basic, Basicv2, Standard, Standardv2, Premium"
  }
}

variable "apim_managed_identity_type" {
  description = "The type of managed identity to be used with API Management"
  type        = string
  default     = "SystemAssigned"
  validation {
    condition     = contains(["SystemAssigned", "UserAssigned", "SystemAssigned, UserAssigned"], var.apim_managed_identity_type)
    error_message = "The apim_managed_identity_type must be one of: SystemAssigned, UserAssigned, SystemAssigned, UserAssigned"
  }
}

variable "apim_user_assigned_managed_identity_id" {
  description = "The user-assigned managed identity ID to be used with API Management"
  type        = string
  default     = ""
}

variable "apim_subscriptions_config" {
  description = "Configuration array for APIM subscriptions"
  type = list(object({
    name        = string
    displayName = string
  }))
  default = []
}

variable "law_id" {
  description = "The Log Analytics Workspace ID for diagnostic settings"
  type        = string
  default     = ""
}

variable "app_insights_instrumentation_key" {
  description = "The instrumentation key for Application Insights"
  type        = string
  default     = ""
  sensitive   = true
}

variable "app_insights_id" {
  description = "The resource ID for Application Insights"
  type        = string
  default     = ""
}

variable "release_channel" {
  description = "The release channel for the API Management service"
  type        = string
  default     = "Default"
  validation {
    condition     = contains(["Early", "Default", "Late", "GenAI"], var.release_channel)
    error_message = "The release_channel must be one of: Early, Default, Late, GenAI"
  }
}

# ------------------
#    LOCALS
# ------------------

locals {
  api_management_name = var.api_management_name != "" ? var.api_management_name : "demo-apim-${var.resource_suffix}"
  
  identity_config = var.apim_managed_identity_type == "UserAssigned" && var.apim_user_assigned_managed_identity_id != "" ? {
    type         = var.apim_managed_identity_type
    identity_ids = [var.apim_user_assigned_managed_identity_id]
  } : {
    type         = var.apim_managed_identity_type
    identity_ids = []
  }
}

# ------------------
#    RESOURCES
# ------------------

resource "azurerm_api_management" "apim" {
  name                = local.api_management_name
  location            = var.location
  resource_group_name = var.resource_group_name
  publisher_name      = var.publisher_name
  publisher_email     = var.publisher_email

  sku_name = "${var.apim_sku}_1"

  dynamic "identity" {
    for_each = [local.identity_config]
    content {
      type         = identity.value.type
      identity_ids = identity.value.type == "UserAssigned" || identity.value.type == "SystemAssigned, UserAssigned" ? identity.value.identity_ids : null
    }
  }

  # Note: release_channel is not directly supported in azurerm provider
  # This would need to be configured via ARM template or API
}

resource "azurerm_monitor_diagnostic_setting" "apim_diagnostics" {
  count                      = var.law_id != "" ? 1 : 0
  name                       = "apimDiagnosticSettings"
  target_resource_id         = azurerm_api_management.apim.id
  log_analytics_workspace_id = var.law_id

  enabled_log {
    category_group = "AllLogs"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

resource "azurerm_api_management_logger" "azure_monitor" {
  count               = var.law_id != "" ? 1 : 0
  name                = "azuremonitor"
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = var.resource_group_name

  resource_id = var.law_id

  application_insights {
    instrumentation_key = ""
  }
}

resource "azurerm_api_management_logger" "app_insights" {
  count               = var.app_insights_id != "" && var.app_insights_instrumentation_key != "" ? 1 : 0
  name                = "appinsights-logger"
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = var.resource_group_name

  application_insights {
    instrumentation_key = var.app_insights_instrumentation_key
  }

  resource_id = var.app_insights_id
}

resource "azurerm_api_management_subscription" "subscriptions" {
  for_each = { for sub in var.apim_subscriptions_config : sub.name => sub }

  api_management_name = azurerm_api_management.apim.name
  resource_group_name = var.resource_group_name
  display_name        = each.value.displayName
  state               = "active"
  allow_tracing       = true

  # Scope to all APIs
  api_id = null
}

# ------------------
#    OUTPUTS
# ------------------

output "id" {
  description = "The ID of the API Management service"
  value       = azurerm_api_management.apim.id
}

output "name" {
  description = "The name of the API Management service"
  value       = azurerm_api_management.apim.name
}

output "principal_id" {
  description = "The Principal ID of the System Assigned Managed Identity"
  value       = var.apim_managed_identity_type == "SystemAssigned" ? azurerm_api_management.apim.identity[0].principal_id : ""
}

output "gateway_url" {
  description = "The Gateway URL of the API Management service"
  value       = azurerm_api_management.apim.gateway_url
}

output "logger_id" {
  description = "The ID of the Azure Monitor logger"
  value       = var.law_id != "" ? azurerm_api_management_logger.azure_monitor[0].id : ""
}

output "apim_subscriptions" {
  description = "List of APIM subscriptions with their keys"
  value = [
    for sub_key, sub in azurerm_api_management_subscription.subscriptions : {
      name        = sub_key
      displayName = sub.display_name
      key         = sub.primary_key
    }
  ]
  sensitive = true
}
