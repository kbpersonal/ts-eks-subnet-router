resource "azurerm_kubernetes_cluster" "main" {
  name                = format("%s-%s-%s-%s-aks", local.tenant, local.environment, local.stage, local.cluster_name)
  location            = local.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = format("%s-%s-%s-%s", local.tenant, local.environment, local.stage, local.cluster_name)
  kubernetes_version  = local.aks_version
  sku_tier            = "Standard"

  default_node_pool {
    name                = "np1"
    vm_size             = local.cluster_vm_size
    node_count          = local.node_count
    vnet_subnet_id      = azurerm_subnet.private[0].id
    enable_auto_scaling = false
    tags                = local.tags
  }

  network_profile {
    network_plugin     = "azure"
    dns_service_ip     = cidrhost(local.aks_service_ipv4_cidr, 10)
    service_cidr       = local.aks_service_ipv4_cidr
    outbound_type      = "userAssignedNATGateway"
    load_balancer_sku  = "standard"
  }

  api_server_authorized_ip_ranges = [] # API server is private
  private_cluster_enabled         = true

  identity {
    type = "SystemAssigned"
  }

  tags = local.tags
}

data "azurerm_kubernetes_cluster" "credentials" {
  depends_on          = [azurerm_kubernetes_cluster.main]
  name                = azurerm_kubernetes_cluster.main.name
  resource_group_name = azurerm_resource_group.main.name
}

