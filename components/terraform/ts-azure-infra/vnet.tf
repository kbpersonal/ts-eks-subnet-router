resource "azurerm_virtual_network" "main" {
  name                = format("%s-%s-%s-vnet", local.tenant, local.environment, local.stage)
  address_space       = [local.vnet_cidr]
  location            = local.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.tags
}

resource "azurerm_subnet" "public" {
  count                = length(local.public_subnets)
  name                 = format("%s-%s-%s-public-%d", local.tenant, local.environment, local.stage, count.index)
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [local.public_subnets[count.index]]
}

resource "azurerm_subnet" "private" {
  count                = length(local.private_subnets)
  name                 = format("%s-%s-%s-private-%d", local.tenant, local.environment, local.stage, count.index)
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [local.private_subnets[count.index]]
}

resource "azurerm_resource_group" "main" {
  name     = format("%s-%s-%s-rg", local.tenant, local.environment, local.stage)
  location = local.location
  tags     = local.tags
}

# NAT Gateway for outbound internet from private subnets
resource "azurerm_public_ip" "nat" {
  name                = format("%s-%s-%s-nat-ip", local.tenant, local.environment, local.stage)
  resource_group_name = azurerm_resource_group.main.name
  location            = local.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags
}

resource "azurerm_nat_gateway" "main" {
  name                = format("%s-%s-%s-natgw", local.tenant, local.environment, local.stage)
  resource_group_name = azurerm_resource_group.main.name
  location            = local.location
  sku_name            = "Standard"
  tags                = local.tags

  public_ip_addresses = [azurerm_public_ip.nat.id]
}

resource "azurerm_subnet_nat_gateway_association" "private" {
  count          = length(local.private_subnets)
  subnet_id      = azurerm_subnet.private[count.index].id
  nat_gateway_id = azurerm_nat_gateway.main.id
}