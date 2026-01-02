resource "azurerm_kubernetes_cluster" "this" {
  name                = "${var.prefix}-aks"
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = "${var.prefix}-aks"
  kubernetes_version  = var.k8s_version

  default_node_pool {
    name           = "system"
    node_count     = 1
    vm_size        = "Standard_B2s"
    vnet_subnet_id = var.system_subnet_id
    only_critical_addons_enabled = true
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin = "azure"
    network_policy = "calico"
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "spot" {
  name                  = "userspot"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.this.id
  vm_size               = "Standard_D2s_v3"
  node_count            = 1
  min_count             = 1
  max_count             = 3
  auto_scaling_enabled = true # new azure upgrade requirement
  priority              = "Spot"
  eviction_policy       = "Delete"
  spot_max_price        = -1
  vnet_subnet_id        = var.user_subnet_id
  node_taints           = ["kubernetes.azure.com/scalesetpriority=spot:NoSchedule"]
}