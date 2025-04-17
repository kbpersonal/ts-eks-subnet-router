# Create the RG for everything
resource "azurerm_resource_group" "main" {
  name     = format("%s-%s-%s-rg", local.tenant, local.environment, local.stage)
  location = local.location
  tags     = local.tags
}

# Create the Vnet
resource "azurerm_virtual_network" "main" {
  name                = format("%s-%s-%s-vnet", local.tenant, local.environment, local.stage)
  address_space       = [local.vnet_cidr]
  location            = local.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.tags
}

# Create the public subnets
resource "azurerm_subnet" "public" {
  count                = length(local.public_subnets)
  name                 = format("%s-%s-%s-public-%d", local.tenant, local.environment, local.stage, count.index)
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [local.public_subnets[count.index]]
}

# Create the private subnets
resource "azurerm_subnet" "private" {
  count                = length(local.private_subnets)
  name                 = format("%s-%s-%s-private-%d", local.tenant, local.environment, local.stage, count.index)
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [local.private_subnets[count.index]]
}

# Create the inbound DNS subnet
resource "azurerm_subnet" "dns-inbound" {
  name                 = format("%s-%s-%s-dns-inbound", local.tenant, local.environment, local.stage)
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [local.dns_inbound_subnet]
  delegation {
    name = "Microsoft.Network.dnsResolvers"
    service_delegation {
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
      name    = "Microsoft.Network/dnsResolvers"
    }
  }
}

# Create the private DNS Resolver
resource "azurerm_private_dns_resolver" "main" {
  name                = format("%s-%s-%s-dns-resolver", local.tenant, local.environment, local.stage)
  resource_group_name = azurerm_resource_group.main.name
  location            = local.location
  virtual_network_id  = azurerm_virtual_network.main.id
  tags                = local.tags
}

# Create the private DNS Resolver Inbound Endpoint
resource "azurerm_private_dns_resolver_inbound_endpoint" "main" {
  name                    = format("%s-%s-%s-dns-resolver-inbound-endpoint", local.tenant, local.environment, local.stage)
  location                = local.location
  private_dns_resolver_id = azurerm_private_dns_resolver.main.id
  tags                    = local.tags
  ip_configurations {
    private_ip_allocation_method = "Dynamic"
    subnet_id                    = azurerm_subnet.dns-inbound.id
  }
}

# NAT Gateway for outbound internet from private subnets
resource "azurerm_nat_gateway" "main" {
  name                    = format("%s-%s-%s-natgw", local.tenant, local.environment, local.stage)
  resource_group_name     = azurerm_resource_group.main.name
  location                = local.location
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10
  tags                    = local.tags
}

# Associate the NAT gateway with the private subnets
resource "azurerm_subnet_nat_gateway_association" "private" {
  count          = length(local.private_subnets)
  subnet_id      = azurerm_subnet.private[count.index].id
  nat_gateway_id = azurerm_nat_gateway.main.id
}

# Create a public IP for the NAT gateway
resource "azurerm_public_ip" "nat" {
  name                = format("%s-%s-%s-nat-pip", local.tenant, local.environment, local.stage)
  resource_group_name = azurerm_resource_group.main.name
  location            = local.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags
}

# Associate the NAT gateway with the public IP  
resource "azurerm_nat_gateway_public_ip_association" "main" {
  nat_gateway_id       = azurerm_nat_gateway.main.id
  public_ip_address_id = azurerm_public_ip.nat.id
}