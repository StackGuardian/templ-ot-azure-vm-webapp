# Helper for the integration test: sends a GET request and returns status and body.
terraform {
  required_providers {
    http = {
      source = "hashicorp/http"
    }
  }
}

variable "url" {
  type = string
}

data "http" "this" {
  url = var.url

  # Retries on connection errors and 5xx (502 while instances are still booting), up to about 15 minutes.
  retry {
    attempts     = 30
    min_delay_ms = 5000
    max_delay_ms = 30000
  }
}

output "status_code" {
  value = data.http.this.status_code
}

output "body" {
  value = data.http.this.response_body
}
