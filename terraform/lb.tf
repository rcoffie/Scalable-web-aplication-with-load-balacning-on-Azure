# Load Balancer
resource "azurerm_lb" "main_lb" {
  name                = "my-load-balancer"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.lb_public_ip.id
  }
}

# Backend Address Pool
resource "azurerm_lb_backend_address_pool" "backend_pool" {
  loadbalancer_id = azurerm_lb.main_lb.id
  name            = "BackEndAddressPool"
}

# Health Probe
resource "azurerm_lb_probe" "health_probe" {
  loadbalancer_id = azurerm_lb.main_lb.id
  name            = "http-health-probe"
  port            = 80
  protocol        = "Http"
  request_path    = "/"
}

# Load Balancing Rule
resource "azurerm_lb_rule" "lb_rule" {
  loadbalancer_id                = azurerm_lb.main_lb.id
  name                           = "LBRule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "PublicIPAddress"
  probe_id                       = azurerm_lb_probe.health_probe.id
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.backend_pool.id]
}
