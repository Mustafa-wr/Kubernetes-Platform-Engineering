terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.100.0" # This allows 3.100.x and above (Safe upgrades)
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6.0"
    }
  }
}