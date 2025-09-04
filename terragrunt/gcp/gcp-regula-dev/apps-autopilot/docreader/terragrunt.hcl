terraform {
  source = "."
}

include "root" {
  path = find_in_parent_folders("root-gcp.hcl")
}

include "provider" {
  path = find_in_parent_folders("provider-k8s-gcp.hcl")
}

dependency "gke" {
  config_path = "../../infra/gke/gke-autopilot"
  mock_outputs = {
    cluster_name     = "mock-cluster"
    cluster_location = "us-central1"
  }
}

dependency "gcs" {
  config_path = "../../infra/gcs/docreader"
  mock_outputs = {
    name = "mock-bucket"
  }
}

dependency "gsql" {
  config_path = "../../infra/gsql"
  mock_outputs = {
    private_ip_address = "10.0.0.1"
    additional_users = [
      { name = "user1", password = "pass1" },
      { name = "faceapi_user", password = "mock_password" }
    ]
    additional_databases = [
      { name = "db1" },
      { name = "faceapi_db" }
    ]
  }
}

locals {
  project  = read_terragrunt_config(find_in_parent_folders("project.hcl")).locals
  app_name = local.project.apps.docreader.name
  deploy   = local.project.apps.docreader.deploy
}

skip = !local.deploy

inputs = {
  database_connection_string = "postgresql://${try(dependency.gsql.outputs.additional_users[0].name, "docreader")}:${try(dependency.gsql.outputs.additional_users[0].password, "password")}@${dependency.gsql.outputs.private_ip_address}:5432/docreader"
  storage_bucket             = dependency.gcs.outputs.name
  cluster_name               = dependency.gke.outputs.name
  cluster_location           = dependency.gke.outputs.location
  project_name               = local.project.project_name
  project_id                 = local.project.gcp_project
  app_namespace              = "${local.app_name}-${local.project.project_env}"
  domain                     = "gcp-${local.app_name}-${local.project.project_env}-autopilot.${local.project.domain}"
  service_account_name       = "${local.app_name}-${local.project.project_env}"
  license_file_path          = "${get_parent_terragrunt_dir("root")}/regula.license"
}