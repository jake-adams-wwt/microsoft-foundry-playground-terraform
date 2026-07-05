terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "sttfstate2olu2f"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}