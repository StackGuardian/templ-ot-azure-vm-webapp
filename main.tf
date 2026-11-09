locals {
  tags = merge(
    {
      Project     = var.name_prefix
      Environment = "demo"
      ManagedBy   = "opentofu"
      Repository  = "tf-azure-vm-webapp"
    },
    var.advanced_settings.tags,
  )
}

resource "azurerm_resource_group" "this" {
  name     = "${var.name_prefix}-vm-webapp-rg"
  location = var.location
  tags     = local.tags
}

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}
