# Use the same cloudinit-ts child module as AWS for Tailscale and Docker setup
module "ubuntu-tailscale-client" {
  source           = "../modules/cloudinit-ts"
  hostname         = local.hostname
  accept_routes    = true
  enable_ssh       = true
  advertise_routes = concat(local.advertise_routes,[azurerm_private_dns_resolver_inbound_endpoint.main.ip_configurations[0].private_ip_address])
  primary_tag      = "subnet-router"
  additional_parts = [
    {
      filename     = "install_docker.sh"
      content_type = "text/x-shellscript"
      content      = file("../files/install_docker.sh")
    }
  ]
}

resource "azurerm_public_ip" "main" {
  name                = format("%s-%s-%s-%s-vm-pip", local.tenant, local.environment, local.stage, local.hostname)
  location            = local.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags
}

resource "azurerm_network_interface" "main" {
  name                = format("%s-%s-%s-%s-vm-nic", local.tenant, local.environment, local.stage, local.hostname)
  location            = local.location
  resource_group_name = azurerm_resource_group.main.name
  ip_forwarding_enabled = true
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.public[0].id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.main.id
  }
  tags = local.tags
}

resource "azurerm_linux_virtual_machine" "main" {
  name                = local.hostname
  location            = local.location
  resource_group_name = azurerm_resource_group.main.name
  size                = local.vm_size
  admin_username      = "ubuntu"
  network_interface_ids = [azurerm_network_interface.main.id]
  admin_ssh_key {
    username   = "ubuntu"
    public_key = file(var.ssh_public_key_path)
  }
  custom_data         = module.ubuntu-tailscale-client.rendered
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  tags = merge(
    local.tags,
    {
      "Name" = var.hostname
    }
  )

  provisioner "remote-exec" {
    inline = [
      "mkdir -p /home/ubuntu/nginx_docker"  # Ensure the directory is created
    ]
  }
  
  provisioner "file" {
    source      = "../files/nginx.conf"  # Local file path
    destination = "/home/ubuntu/nginx_docker/nginx.conf"  # Target path
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(var.ssh_private_key_path)
    host        = azurerm_public_ip.main.ip_address
  }
}

resource "azurerm_network_security_group" "main" {
  name                = format("%s-%s-%s-%s-vm-nsg", local.tenant, local.environment, local.stage, local.hostname)
  location            = local.location
  resource_group_name = azurerm_resource_group.main.name
  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "TailscaleWG"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "41641"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "AllowAllOutbound"
    priority                   = 1003
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  tags = local.tags
}

resource "azurerm_network_interface_security_group_association" "main" {
  network_interface_id      = azurerm_network_interface.main.id
  network_security_group_id = azurerm_network_security_group.main.id
}
