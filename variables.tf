variable "name_prefix" {
  description = "Prefix for all resource names"
  type        = string
  default     = "demo"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,15}$", var.name_prefix))
    error_message = "Use 2-16 lowercase letters, digits or hyphens, starting with a letter."
  }
}

variable "location" {
  description = "Azure location"
  type        = string
  default     = "germanywestcentral"
}

variable "vnet_cidr" {
  description = "Address space of the VNet"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.vnet_cidr))
    error_message = "Must be a valid IPv4 CIDR block."
  }
}

variable "vm_size" {
  description = "VM size of the scale set instances. Must support Trusted Launch (Gen2)."
  type        = string
  default     = "Standard_B2s_v2"
}

variable "ssh_public_key" {
  description = "SSH public key for the admin user. Password login is disabled and no SSH port is open."
  type        = string

  validation {
    condition     = can(regex("^(ssh-(rsa|ed25519)|ecdsa-sha2-nistp[0-9]+) ", var.ssh_public_key))
    error_message = "Must be an OpenSSH public key, for example ssh-ed25519 AAAA..."
  }
}

# Grouped so the StackGuardian form can show them in one "Advanced Settings" section.
variable "advanced_settings" {
  description = "Settings most deployments keep at their defaults"
  type = object({
    instance_count             = optional(number, 2)                   # Number of scale set instances
    admin_username             = optional(string, "azureuser")         # Admin user on the instances
    allowed_http_cidrs         = optional(list(string), ["0.0.0.0/0"]) # IPv4 CIDRs allowed to reach the Application Gateway, public by default
    encryption_at_host_enabled = optional(bool, false)                 # Needs the EncryptionAtHost feature registered in the subscription
    log_retention_days         = optional(number, 90)                  # Retention of the logs in Log Analytics
    tags                       = optional(map(string), {})             # Additional tags for all resources
  })
  default  = {}
  nullable = false

  validation {
    condition     = var.advanced_settings.instance_count >= 1
    error_message = "At least one instance is needed."
  }

  validation {
    condition     = alltrue([for c in var.advanced_settings.allowed_http_cidrs : can(cidrnetmask(c))])
    error_message = "All entries in allowed_http_cidrs must be valid IPv4 CIDR blocks."
  }

  validation {
    condition     = var.advanced_settings.log_retention_days >= 30 && var.advanced_settings.log_retention_days <= 730
    error_message = "Log Analytics retention must be between 30 and 730 days."
  }
}
