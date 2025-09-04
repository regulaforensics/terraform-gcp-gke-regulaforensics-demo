include "root" {
  path = find_in_parent_folders("root-gcp.hcl")
}

include "provider" {
  path = find_in_parent_folders("provider-gcp.hcl")
}

locals {
  project = read_terragrunt_config(find_in_parent_folders("project.hcl")).locals
}

dependency "vpc" {
  config_path = "../vpc"
  mock_outputs = {
    network_name = "default"
  }
}

terraform {
  source = "tfr:///terraform-google-modules/sql-db/google//modules/private_service_access//.?version=26.1.0"
}

inputs = {
  project_id      = local.project.gcp_project
  vpc_network     = dependency.vpc.outputs.network_name
  address         = "10.21.146.0"
  prefix_length   = "23"
  deletion_policy = "ABANDON"
}