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
  k8s_version         = "1.34.0"
  system_subnet_id    = module.network.system_subnet_id
  user_subnet_id      = module.network.user_subnet_id
}

provider "vault" {
  # In locally, we port-forward Vault to localhost:8200
  address = "http://127.0.0.1:8200"
  token   = "root" # The dev-mode root token we set in the Helm chart
}

module "vault_config" {
  source = "../../modules/vault_config"

  kubernetes_host    = module.aks.host
  kubernetes_ca_cert = module.aks.ca_certificate
  
  # For the lab, we often skip the strict JWT check or pass a temp one
  db_password = var.vault_db_password
}