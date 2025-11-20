/**
 * @module appinsights-v1
 * @description This module defines the Azure Application Insights (AppInsights) resources using Terraform.
 * This is version 1 (v1) of the AppInsights Terraform module.
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
  description = "The suffix to append to the Application Insights name"
  type        = string
  default     = ""
}

variable "application_insights_name" {
  description = "Name of the Application Insights resource"
  type        = string
  default     = ""
}

variable "application_insights_location" {
  description = "Location of the Application Insights resource"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "custom_metrics_opted_in_type" {
  description = "The custom metrics opted in type"
  type        = string
  default     = "Off"
  validation {
    condition     = contains(["WithDimensions", "NoDimensions", "NoMeasurements", "Off"], var.custom_metrics_opted_in_type)
    error_message = "The custom_metrics_opted_in_type must be one of: WithDimensions, NoDimensions, NoMeasurements, Off"
  }
}

variable "use_workbook" {
  description = "Indicate whether workbook is used"
  type        = bool
  default     = false
}

variable "workbook_name" {
  description = "Name for the Workbook"
  type        = string
  default     = "UsageAnalysis"
}

variable "workbook_location" {
  description = "Location for the Workbook"
  type        = string
}

variable "workbook_display_name" {
  description = "Display Name for the Workbook"
  type        = string
  default     = "Usage Analysis"
}

variable "workbook_json" {
  description = "JSON string for the Workbook"
  type        = string
  default     = ""
}

variable "law_id" {
  description = "Log Analytics Workspace Id"
  type        = string
}

# ------------------
#    LOCALS
# ------------------

locals {
  application_insights_name = var.application_insights_name != "" ? var.application_insights_name : "insights-${var.resource_suffix}"
}

# ------------------
#    RESOURCES
# ------------------

resource "azurerm_application_insights" "app_insights" {
  name                = local.application_insights_name
  location            = var.application_insights_location
  resource_group_name = var.resource_group_name
  workspace_id        = var.law_id
  application_type    = "web"

  # Note: CustomMetricsOptedInType is not directly supported in azurerm provider
  # This would need to be configured via ARM template or API
}

resource "azurerm_application_insights_workbook" "usage_workbook" {
  count               = var.use_workbook ? 1 : 0
  name                = "${var.resource_group_name}-${var.workbook_name}"
  resource_group_name = var.resource_group_name
  location            = var.workbook_location
  display_name        = var.workbook_display_name
  data_json           = var.workbook_json
  source_id           = azurerm_application_insights.app_insights.id
  category            = "workbook"
}

# ------------------
#    OUTPUTS
# ------------------

output "id" {
  description = "The ID of the Application Insights instance"
  value       = azurerm_application_insights.app_insights.id
}

output "name" {
  description = "The name of the Application Insights instance"
  value       = azurerm_application_insights.app_insights.name
}

output "instrumentation_key" {
  description = "The Instrumentation Key for Application Insights"
  value       = azurerm_application_insights.app_insights.instrumentation_key
  sensitive   = true
}

output "app_id" {
  description = "The App ID associated with this Application Insights instance"
  value       = azurerm_application_insights.app_insights.app_id
}

output "application_insights_name" {
  description = "The name of the Application Insights resource"
  value       = local.application_insights_name
}
