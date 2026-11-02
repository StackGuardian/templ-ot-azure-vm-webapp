# Integration tests: deploy real resources, check them, then destroy them.
# This costs money and needs cloud credentials.
# Run: tofu test -test-directory=tests/integration
# Test case catalog: tests/README.md

variables {
  name_prefix = "itest"
  # Throwaway test key, the private key was discarded.
  ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCx5BjE6HIv/f9JIjDM/6y459/JJ17pHQxFUaUoE9DXcKBS3AXuPUuv2Qfrlke/xImnSzfAIWAcUmjBhU1i523XrqOFYzqJM3CV4KbU8UJMiXDRx16qdAt8CacqMd4qOxjSXkkFTDElOMfh9TMChBI3VcshCuQevk9g6y54cpY+y+1ejU/hmfytubSKuXDZ2wfnqEZhQ8RBD9i6TPiQ1OcqUEUEt7WHvtlxx4c4WPkQdG+Sc/EvvglyqmIcye9FCQNDt0NUjMr2mMYyuAjj0pbpMcGoFACw98DN1Y6K3ZkahE65E2uo3b54RWifgGfgMCI2jhFs1KxM02aOLGpijddhkWjP8yRSchJvY5wVkJKzjZSlTaPA2kUiShprjZIEfW4OnNStk+UV0uDRHxTcm28EUuBEceL5qXnZt/f/fdyCJrLYrphd6OjD/oNOVMkTmE96DdzYuZCM9UNT1eyhwRIFsxks9VpCSh8dz02MBJAfRJNGd7VgSLQwiN1/WADaw9M= tofu-test-only"
  tags = {
    Purpose = "integration-test"
  }
}

run "deploy" {
  command = apply
}

# I-01: retries until cloud-init has installed nginx and the probe marks the instances healthy.
run "web_app_is_served" {
  module {
    source = "./tests/integration/http-check"
  }

  variables {
    url = run.deploy.url
  }

  assert {
    condition     = output.status_code == 200 && strcontains(output.body, "demo-marker: vm-webapp-ok")
    error_message = "The Application Gateway did not return the demo page."
  }
}
