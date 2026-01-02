terraform {
  required_version = ">= 1.5.0"

  backend "azurerm" {
    resource_group_name  = "tfstate-rg"          
    storage_account_name = "mustafastate123"     
    container_name       = "tfstate"              
    key                  = "falcon-dev.tfstate"   
  }
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.100.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6.0"
    }
  }
}