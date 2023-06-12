
# For more information on configuring TFlint; see https://github.com/terraform-linters/tflint/blob/master/docs/user-guide/config.md

# For more information on plugins see https://github.com/terraform-linters/tflint/blob/master/docs/user-guide/plugins.md

# For more information on TFlint Ruleset for Terraform; see https://github.com/terraform-linters/tflint-ruleset-terraform/blob/v0.3.0/docs/rules/README.md

# For more information on TFlint Ruleset for GCP, see https://github.com/terraform-linters/tflint-ruleset-google/blob/master/README.md

config {
  # Enables module inspection.
  module = true
}

plugin "google" {
    enabled = true
    version = "0.23.1"
    source  = "github.com/terraform-linters/tflint-ruleset-google"
}

plugin "terraform" {
  enabled = true
  preset = "recommended"
}

