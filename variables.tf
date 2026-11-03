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

variable "tags" {
  description = "Additional tags for all resources"
  type        = map(string)
  default     = {}
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

variable "instance_count" {
  description = "Number of scale set instances"
  type        = number
  default     = 2

  validation {
    condition     = var.instance_count >= 1
    error_message = "At least one instance is needed."
  }
}

variable "admin_username" {
  description = "Admin user on the instances"
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key" {
  description = "SSH public key for the admin user. Password login is disabled and no SSH port is open."
  type        = string

  validation {
    condition     = can(regex("^(ssh-(rsa|ed25519)|ecdsa-sha2-nistp[0-9]+) ", var.ssh_public_key))
    error_message = "Must be an OpenSSH public key, for example ssh-ed25519 AAAA..."
  }
}

variable "allowed_http_cidrs" {
  description = "IPv4 CIDRs allowed to reach the Application Gateway. The web app is public by default."
  type        = list(string)
  default     = ["0.0.0.0/0"]

  validation {
    condition     = alltrue([for c in var.allowed_http_cidrs : can(cidrnetmask(c))])
    error_message = "All entries must be valid IPv4 CIDR blocks."
  }
}

variable "encryption_at_host_enabled" {
  description = "Encrypt temp disk and caches on the host. Needs the EncryptionAtHost feature registered in the subscription."
  type        = bool
  default     = false
}

variable "log_retention_days" {
  description = "Retention of the logs in Log Analytics"
  type        = number
  default     = 90

  validation {
    condition     = var.log_retention_days >= 30 && var.log_retention_days <= 730
    error_message = "Log Analytics retention must be between 30 and 730 days."
  }
}
