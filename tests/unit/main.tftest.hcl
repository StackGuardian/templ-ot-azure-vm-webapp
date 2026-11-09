# Unit tests: plan only, providers are mocked. No cloud account, no cost.
# Run: tofu test -test-directory=tests/unit
# Test case catalog: tests/README.md

# Some arguments are validated as Azure resource IDs, so mocked IDs must look real.
mock_provider "azurerm" {
  mock_resource "azurerm_resource_group" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg"
    }
  }

  mock_resource "azurerm_virtual_network" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg/providers/Microsoft.Network/virtualNetworks/mock-vnet"
    }
  }

  mock_resource "azurerm_subnet" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg/providers/Microsoft.Network/virtualNetworks/mock-vnet/subnets/mock-subnet"
    }
  }

  mock_resource "azurerm_network_security_group" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg/providers/Microsoft.Network/networkSecurityGroups/mock-nsg"
    }
  }

  mock_resource "azurerm_public_ip" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg/providers/Microsoft.Network/publicIPAddresses/mock-pip"
    }
  }

  mock_resource "azurerm_nat_gateway" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg/providers/Microsoft.Network/natGateways/mock-nat"
    }
  }

  mock_resource "azurerm_application_gateway" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg/providers/Microsoft.Network/applicationGateways/mock-appgw"
    }
  }

  mock_resource "azurerm_log_analytics_workspace" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg/providers/Microsoft.OperationalInsights/workspaces/mock-law"
    }
  }
}

variables {
  # Throwaway test key, the private key was discarded.
  ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCx5BjE6HIv/f9JIjDM/6y459/JJ17pHQxFUaUoE9DXcKBS3AXuPUuv2Qfrlke/xImnSzfAIWAcUmjBhU1i523XrqOFYzqJM3CV4KbU8UJMiXDRx16qdAt8CacqMd4qOxjSXkkFTDElOMfh9TMChBI3VcshCuQevk9g6y54cpY+y+1ejU/hmfytubSKuXDZ2wfnqEZhQ8RBD9i6TPiQ1OcqUEUEt7WHvtlxx4c4WPkQdG+Sc/EvvglyqmIcye9FCQNDt0NUjMr2mMYyuAjj0pbpMcGoFACw98DN1Y6K3ZkahE65E2uo3b54RWifgGfgMCI2jhFs1KxM02aOLGpijddhkWjP8yRSchJvY5wVkJKzjZSlTaPA2kUiShprjZIEfW4OnNStk+UV0uDRHxTcm28EUuBEceL5qXnZt/f/fdyCJrLYrphd6OjD/oNOVMkTmE96DdzYuZCM9UNT1eyhwRIFsxks9VpCSh8dz02MBJAfRJNGd7VgSLQwiN1/WADaw9M= tofu-test-only"
}

# U-01
run "defaults_are_valid" {
  command = plan

  assert {
    condition = (
      local.tags["Environment"] == "demo" &&
      local.tags["ManagedBy"] == "opentofu" &&
      local.tags["Project"] == var.name_prefix &&
      local.tags["Repository"] != ""
    )
    error_message = "Default tags are missing or wrong."
  }
}

# U-02
run "invalid_name_prefix_is_rejected" {
  command = plan

  variables {
    name_prefix = "Invalid_Prefix"
  }

  expect_failures = [var.name_prefix]
}

# U-03
run "custom_tags_are_merged" {
  command = plan

  variables {
    advanced_settings = {
      tags = {
        Owner = "tester"
      }
    }
  }

  assert {
    condition     = local.tags["Owner"] == "tester" && local.tags["ManagedBy"] == "opentofu"
    error_message = "Custom tags are not merged with the default tags."
  }
}

# U-04
run "instances_have_no_public_ip" {
  command = apply

  assert {
    condition = alltrue([
      for nic in azurerm_linux_virtual_machine_scale_set.web.network_interface :
      alltrue([for ip in nic.ip_configuration : length(ip.public_ip_address) == 0 && ip.subnet_id == azurerm_subnet.web.id])
    ])
    error_message = "Instances must be in the web subnet without public IPs."
  }

  assert {
    condition     = !azurerm_subnet.web.default_outbound_access_enabled
    error_message = "Default outbound access must be disabled, outbound goes through the NAT gateway."
  }
}

# U-05
run "instances_are_hardened" {
  command = apply

  assert {
    condition     = azurerm_linux_virtual_machine_scale_set.web.disable_password_authentication
    error_message = "Password authentication must be disabled."
  }

  assert {
    condition     = azurerm_linux_virtual_machine_scale_set.web.secure_boot_enabled && azurerm_linux_virtual_machine_scale_set.web.vtpm_enabled
    error_message = "Trusted Launch (Secure Boot and vTPM) must be enabled."
  }

  assert {
    condition     = !azurerm_linux_virtual_machine_scale_set.web.extension_operations_enabled
    error_message = "VM extensions must be disabled."
  }

  assert {
    condition     = one(azurerm_linux_virtual_machine_scale_set.web.identity).type == "SystemAssigned"
    error_message = "Instances must have a managed identity."
  }
}

# U-06
run "web_subnet_accepts_http_only_from_appgw" {
  command = apply

  assert {
    condition = anytrue([
      for r in azurerm_network_security_group.web.security_rule :
      r.access == "Allow" && r.destination_port_range == "80" && r.source_address_prefix == azurerm_subnet.appgw.address_prefixes[0]
    ])
    error_message = "HTTP must be allowed from the Application Gateway subnet."
  }

  assert {
    condition = alltrue([
      for r in azurerm_network_security_group.web.security_rule :
      r.access == "Deny" || contains([azurerm_subnet.appgw.address_prefixes[0], "AzureLoadBalancer"], r.source_address_prefix)
    ])
    error_message = "The web subnet must not allow inbound traffic from other sources."
  }

  assert {
    condition = anytrue([
      for r in azurerm_network_security_group.web.security_rule :
      r.access == "Deny" && r.source_address_prefix == "*" && r.destination_port_range == "*"
    ])
    error_message = "The web subnet must deny all other inbound traffic."
  }
}

# U-07
run "appgw_allows_only_given_cidrs" {
  command = apply

  variables {
    advanced_settings = {
      allowed_http_cidrs = ["203.0.113.0/24"]
    }
  }

  assert {
    condition = alltrue([
      for r in azurerm_network_security_group.appgw.security_rule :
      toset(r.source_address_prefixes) == toset(["203.0.113.0/24"]) if r.destination_port_range == "80"
    ])
    error_message = "Port 80 on the Application Gateway must be open only to allowed_http_cidrs."
  }
}

# U-08
run "access_logs_are_enabled" {
  command = apply

  assert {
    condition = (
      azurerm_monitor_diagnostic_setting.appgw.target_resource_id == azurerm_application_gateway.this.id &&
      contains([for l in azurerm_monitor_diagnostic_setting.appgw.enabled_log : l.category], "ApplicationGatewayAccessLog")
    )
    error_message = "Application Gateway access logs must go to Log Analytics."
  }
}
