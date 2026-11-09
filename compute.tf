resource "azurerm_linux_virtual_machine_scale_set" "web" {
  #checkov:skip=CKV_AZURE_97:Encryption at host needs a subscription feature, configurable via encryption_at_host_enabled
  name                            = "${var.name_prefix}-web"
  location                        = azurerm_resource_group.this.location
  resource_group_name             = azurerm_resource_group.this.name
  sku                             = var.vm_size
  instances                       = var.advanced_settings.instance_count
  admin_username                  = var.advanced_settings.admin_username
  disable_password_authentication = true
  secure_boot_enabled             = true
  vtpm_enabled                    = true
  encryption_at_host_enabled      = var.advanced_settings.encryption_at_host_enabled
  extension_operations_enabled    = false
  custom_data                     = filebase64("${path.module}/cloud-init.yaml")
  upgrade_mode                    = "Manual"
  tags                            = local.tags

  admin_ssh_key {
    username   = var.advanced_settings.admin_username
    public_key = var.ssh_public_key
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  # Managed disks are encrypted at rest with platform-managed keys.
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  network_interface {
    name    = "web"
    primary = true

    ip_configuration {
      name                                         = "internal"
      primary                                      = true
      subnet_id                                    = azurerm_subnet.web.id
      application_gateway_backend_address_pool_ids = [one(azurerm_application_gateway.this.backend_address_pool).id]
    }
  }

  identity {
    type = "SystemAssigned"
  }

  boot_diagnostics {}

  depends_on = [
    azurerm_subnet_nat_gateway_association.web,
    azurerm_subnet_network_security_group_association.web,
  ]
}
