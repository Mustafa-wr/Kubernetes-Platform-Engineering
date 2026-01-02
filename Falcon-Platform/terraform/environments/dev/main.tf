provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

resource "azurerm_resource_group" "rg" {
  name     = "${var.project_name}-${var.environment}-rg"
  location = var.location
}

module "network" {
  source              = "../../modules/network"
  prefix              = "${var.project_name}-${var.environment}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

module "aks" {
  source              = "../../modules/aks"
  prefix              = "${var.project_name}-${var.environment}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  k8s_version         = "1.29.0"
  system_subnet_id    = module.network.system_subnet_id
  user_subnet_id      = module.network.user_subnet_id
}