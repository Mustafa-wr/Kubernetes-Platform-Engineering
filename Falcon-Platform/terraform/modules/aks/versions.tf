terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.90.0" # This allows 3.90.x but not 4.0 (Safe upgrades)
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6.0"
    }
  }
}