plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

plugin "azurerm" {
  enabled = true
  version = "0.33.0"
  source  = "github.com/terraform-linters/tflint-ruleset-azurerm"
}

# Demo templates are meant to be destroyed after the demo.
rule "azurerm_resources_missing_prevent_destroy" {
  enabled = false
}
