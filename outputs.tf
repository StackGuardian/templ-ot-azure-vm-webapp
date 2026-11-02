output "url" {
  description = "URL of the web app"
  value       = "http://${azurerm_public_ip.appgw.fqdn}"
}

output "public_ip" {
  description = "Public IP of the Application Gateway"
  value       = azurerm_public_ip.appgw.ip_address
}

output "scale_set_name" {
  description = "Name of the VM Scale Set"
  value       = azurerm_linux_virtual_machine_scale_set.web.name
}

output "application_gateway_name" {
  description = "Name of the Application Gateway"
  value       = azurerm_application_gateway.this.name
}

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.this.name
}
