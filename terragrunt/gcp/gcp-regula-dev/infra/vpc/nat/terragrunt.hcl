include "root" {
  path = find_in_parent_folders("root-gcp.hcl")
}

include "provider" {
  path = find_in_parent_folders("provider-gcp.hcl")
}

locals {
  project = read_terragrunt_config(find_in_parent_folders("project.hcl")).locals
}

terraform {
  source = "tfr:///terraform-google-modules/cloud-router/google?version=6.2.0"
}

dependency "vpc" {
  config_path = "../vpc"
  mock_outputs = {
    network_name = "mock"
  }
}

inputs = {
  project = local.project.gcp_project
  region  = local.project.gcp_region
  name    = "${local.project.gcp_project}-router"
  network = dependency.vpc.outputs.network_name

  nats = [{
    name = "${local.project.gcp_project}-nat"
    log_config = {
      enable = false
    }
  }]
}