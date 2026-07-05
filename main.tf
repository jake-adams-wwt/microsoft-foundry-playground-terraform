terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.80"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "azurerm" {
  features {}
}

data "azurerm_client_config" "current" {}

# Ensures custom_subdomain_name is globally unique across all Azure tenants
resource "random_string" "subdomain_suffix" {
  length  = 6
  special = false
  upper   = false
}

locals {
  product_name           = var.product_name
  formatted_product_name = lower(replace(var.product_name, " ", "-"))
  location               = var.location
  standard_tags          = var.standard_tags

  # Alphanumeric-only variant for resources that disallow hyphens
  # (storage accounts). Truncated where length limits apply.
  compact_product_name = lower(replace(var.product_name, "/[^a-zA-Z0-9]/", ""))
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-${local.formatted_product_name}"
  location = local.location
  tags     = local.standard_tags
}

# # Log analytics workspace
# resource "azurerm_log_analytics_workspace" "law" {
#   name                = "log-${local.formatted_product_name}"
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name
#   sku                 = "PerGB2018"
#   retention_in_days   = 30
#   tags                = local.standard_tags
# }

# # Application insights
# resource "azurerm_application_insights" "appi" {
#   name                = "appi-${local.formatted_product_name}"
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name
#   workspace_id        = azurerm_log_analytics_workspace.law.id
#   application_type    = "web"
#   tags                = local.standard_tags
# }

# # Key vault (3-24 chars, alphanumeric and hyphens)
# resource "azurerm_key_vault" "kv" {
#   name                       = substr("kv-${local.formatted_product_name}", 0, 24)
#   location                   = azurerm_resource_group.rg.location
#   resource_group_name        = azurerm_resource_group.rg.name
#   tenant_id                  = data.azurerm_client_config.current.tenant_id
#   sku_name                   = "standard"
#   purge_protection_enabled   = false
#   soft_delete_retention_days = 7
#   tags                       = local.standard_tags
# }

# # Storage account (3-24 chars, lowercase alphanumeric only)
# resource "azurerm_storage_account" "st" {
#   name                     = substr("st${local.compact_product_name}", 0, 24)
#   location                 = azurerm_resource_group.rg.location
#   resource_group_name      = azurerm_resource_group.rg.name
#   account_tier             = "Standard"
#   account_replication_type = "LRS"
#   min_tls_version          = "TLS1_2"
#   tags                     = local.standard_tags
# }

# Microsoft Foundry resource (Cognitive Services account, kind AIServices)
resource "azurerm_cognitive_account" "ai_foundry" {
  name                = "aif-${local.formatted_product_name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  kind                = "AIServices"
  sku_name            = "S0"

  # Required for stateful Foundry development including the agent service
  custom_subdomain_name      = "${local.formatted_product_name}-${random_string.subdomain_suffix.result}"
  project_management_enabled = true

  identity {
    type = "SystemAssigned"
  }

  tags = local.standard_tags
}

# Microsoft Foundry project
resource "azurerm_cognitive_account_project" "project" {
  name                 = "proj-${local.formatted_product_name}"
  cognitive_account_id = azurerm_cognitive_account.ai_foundry.id
  location             = azurerm_resource_group.rg.location

  identity {
    type = "SystemAssigned"
  }

  tags = local.standard_tags
}