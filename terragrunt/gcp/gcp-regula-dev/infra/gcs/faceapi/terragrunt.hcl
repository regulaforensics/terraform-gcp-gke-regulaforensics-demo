include "root" {
  path = find_in_parent_folders("root-gcp.hcl")
}

include "provider" {
  path = find_in_parent_folders("provider-gcp.hcl")
}

locals {
  project  = read_terragrunt_config(find_in_parent_folders("project.hcl")).locals
  app_name = "faceapi"
  deploy   = local.project.apps.faceapi.deploy
}

skip = !local.deploy

terraform {
  source = "tfr:///terraform-google-modules/cloud-storage/google//modules/simple_bucket?version=10.0.1"
}

inputs = {
  project_id    = local.project.gcp_project
  name          = "${local.project.project_name}-${local.project.project_env}-${local.app_name}"
  location      = local.project.gcp_region
  force_destroy = true
}