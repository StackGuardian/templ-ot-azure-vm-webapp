locals {
  appgw = {
    frontend_ip   = "public"
    frontend_port = "http"
    backend_pool  = "web"
    http_settings = "web-http"
    probe         = "web-root"
    listener      = "http"
    rule          = "web"
  }
}

resource "azurerm_public_ip" "appgw" {
  name                = "${var.name_prefix}-appgw-pip"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = "${var.name_prefix}-web-${random_string.suffix.result}"
  tags                = local.tags
}

resource "azurerm_application_gateway" "this" {
  #checkov:skip=CKV_AZURE_120:WAF_v2 is out of scope for the demo (cost)
  #checkov:skip=CKV_AZURE_217:HTTPS needs a certificate in Key Vault, out of scope for the demo
  #checkov:skip=CKV_AZURE_218:TLS policy applies only to HTTPS listeners, which are out of scope
  name                = "${var.name_prefix}-appgw"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  http2_enabled       = true
  tags                = local.tags

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 1
  }

  ssl_policy {
    policy_type = "Predefined"
    policy_name = "AppGwSslPolicy20220101"
  }

  gateway_ip_configuration {
    name      = "gateway"
    subnet_id = azurerm_subnet.appgw.id
  }

  frontend_ip_configuration {
    name                 = local.appgw.frontend_ip
    public_ip_address_id = azurerm_public_ip.appgw.id
  }

  frontend_port {
    name = local.appgw.frontend_port
    port = 80
  }

  backend_address_pool {
    name = local.appgw.backend_pool
  }

  probe {
    name                                      = local.appgw.probe
    protocol                                  = "Http"
    path                                      = "/"
    interval                                  = 15
    timeout                                   = 10
    unhealthy_threshold                       = 3
    pick_host_name_from_backend_http_settings = true
  }

  backend_http_settings {
    name                                = local.appgw.http_settings
    protocol                            = "Http"
    port                                = 80
    cookie_based_affinity               = "Disabled"
    request_timeout                     = 30
    probe_name                          = local.appgw.probe
    pick_host_name_from_backend_address = true
  }

  http_listener {
    name                           = local.appgw.listener
    frontend_ip_configuration_name = local.appgw.frontend_ip
    frontend_port_name             = local.appgw.frontend_port
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = local.appgw.rule
    priority                   = 100
    rule_type                  = "Basic"
    http_listener_name         = local.appgw.listener
    backend_address_pool_name  = local.appgw.backend_pool
    backend_http_settings_name = local.appgw.http_settings
  }

  depends_on = [azurerm_subnet_network_security_group_association.appgw]
}

# Access logs of the Application Gateway
resource "azurerm_log_analytics_workspace" "this" {
  name                = "${var.name_prefix}-vm-webapp-logs"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days
  tags                = local.tags
}

resource "azurerm_monitor_diagnostic_setting" "appgw" {
  name                       = "access-logs"
  target_resource_id         = azurerm_application_gateway.this.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  enabled_log {
    category = "ApplicationGatewayAccessLog"
  }
}
