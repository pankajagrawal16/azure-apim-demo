/**
 * @module workspaces-v1
 * @description This module defines the Azure Log Analytics Workspaces (LAW) resources using Terraform.
 * This is version 1 (v1) of the LAW Terraform module.
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
  description = "The suffix to append to the Log Analytics name"
  type        = string
  default     = ""
}

variable "log_analytics_name" {
  description = "Name of the Log Analytics resource"
  type        = string
  default     = ""
}

variable "log_analytics_location" {
  description = "Location of the Log Analytics resource"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

# ------------------
#    LOCALS
# ------------------

locals {
  log_analytics_name = var.log_analytics_name != "" ? var.log_analytics_name : "workspace-${var.resource_suffix}"
}

# ------------------
#    RESOURCES
# ------------------

resource "azurerm_log_analytics_workspace" "workspace" {
  name                = local.log_analytics_name
  location            = var.log_analytics_location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  identity {
    type = "SystemAssigned"
  }
}

# ------------------
#    OUTPUTS
# ------------------

output "id" {
  description = "The ID of the Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.workspace.id
}

output "name" {
  description = "The name of the Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.workspace.name
}

output "customer_id" {
  description = "The Workspace (or Customer) ID for the Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.workspace.workspace_id
}

output "primary_shared_key" {
  description = "The Primary shared key for the Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.workspace.primary_shared_key
  sensitive   = true
}
