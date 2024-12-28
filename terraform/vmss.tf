# Network Security Group
resource "azurerm_network_security_group" "lb_nsg" {
  name                = "load-balancer-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "allow-http"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Network Security Group Subnet Association
resource "azurerm_subnet_network_security_group_association" "nsg_subnet_assoc" {
  subnet_id                 = azurerm_subnet.internal.id
  network_security_group_id = azurerm_network_security_group.lb_nsg.id
}

# NAT Pool for VMSS (for SSH access)
resource "azurerm_lb_nat_pool" "ssh_nat_pool" {
  resource_group_name            = azurerm_resource_group.main.name
  name                           = "ssh-nat-pool"
  loadbalancer_id                = azurerm_lb.main_lb.id
  protocol                       = "Tcp"
  frontend_port_start            = 50000
  frontend_port_end              = 50099
  backend_port                   = 22
  frontend_ip_configuration_name = "PublicIPAddress"
}

# Virtual Machine Scale Set
resource "azurerm_linux_virtual_machine_scale_set" "vmss" {
  name                = "my-vmss"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Standard_F2"
  instances           = 2
  admin_username      = "adminuser"

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name    = "example-nic"
    primary = true

    ip_configuration {
      name                                   = "internal"
      primary                                = true
      subnet_id                              = azurerm_subnet.internal.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.backend_pool.id]
      load_balancer_inbound_nat_rules_ids    = [azurerm_lb_nat_pool.ssh_nat_pool.id]
    }
  }

  admin_ssh_key {
    username = "adminuser"
    # public_key = file("~/.ssh/id_rsa.pub")
    public_key = file("~/.ssh/id_rsa.pub")
  }

  # Optional: Install a simple web server to demonstrate load balancing
  custom_data = base64encode(<<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y nginx
              echo "Hello from $(hostname)" > /var/www/html/index.html
              systemctl start nginx
              systemctl enable nginx
              EOF
  )
}
