terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.10"
    }
  }
  required_version = ">= 1.2.3"
}

provider "azurerm" {
  features {}
}

locals {
  product_name  = var.product_name
  formatted_product_name  = lower(replace(var.product_name," ", "-"))
  location      = var.location
  standard_tags = var.standard_tags
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-${local.formatted_product_name}"
  location = local.location
  tags     = local.standard_tags
}