locals {
  project = read_terragrunt_config(find_in_parent_folders("project.hcl")).locals
}

generate "provider-google" {
  path      = "_provider_google.tf"
  if_exists = "overwrite"
  contents  = <<EOF

provider "google" {
  project = "${local.project.gcp_project}"
  region  = "${local.project.gcp_region}"
  add_terraform_attribution_label = false

  default_labels = {
      project = "${local.project.gcp_project}"
      managedby             = "terraform"
      environment           = "${local.project.project_env}"
  }
}

EOF
}
