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
  source = "tfr:///terraform-google-modules/project-factory/google//modules/project_services?version=18.0.0"
}

inputs = {
  project_id = local.project.gcp_project
  
  activate_apis = [
    "compute.googleapis.com",
    "container.googleapis.com",
    "sqladmin.googleapis.com",
    "storage.googleapis.com",
    "iam.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "servicenetworking.googleapis.com",
    "monitoring.googleapis.com",
    "logging.googleapis.com"
  ]
  
  disable_services_on_destroy = false
  disable_dependent_services  = true
}