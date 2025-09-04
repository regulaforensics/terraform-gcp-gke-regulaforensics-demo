include "root" {
  path = find_in_parent_folders("root-gcp.hcl")
}

include "provider" {
  path = find_in_parent_folders("provider-gcp.hcl")
}

dependency "gke" {
  config_path = local.project.gke_cluster_type == "autopilot" ? "../../gke-autopilot" : "../../gke-cluster"
  mock_outputs = {
    gke_output = "mock-gke-output"
  }
}

locals {
  project  = read_terragrunt_config(find_in_parent_folders("project.hcl")).locals
  app_name = "docreader"
  app_namespace = "${local.app_name}-${local.project.project_env}"
  service_account_name = "${local.app_name}-${local.project.project_env}"
  deploy   = local.project.apps.docreader.deploy
}

skip = !local.deploy

terraform {
  source = "tfr:///terraform-google-modules/iam/google//modules/projects_iam//.?version=8.1.0"
}

inputs = {
  projects = [local.project.gcp_project]
  mode     = "additive"
  bindings = {
    "roles/cloudsql.client" = [
      "principal://iam.googleapis.com/projects/${local.project.gcp_project_number}/locations/global/workloadIdentityPools/${local.project.gcp_project}.svc.id.goog/subject/ns/${local.app_namespace}/sa/${local.service_account_name}"
    ]
    "roles/iam.workloadIdentityUser" = [
      "principal://iam.googleapis.com/projects/${local.project.gcp_project_number}/locations/global/workloadIdentityPools/${local.project.gcp_project}.svc.id.goog/subject/ns/${local.app_namespace}/sa/${local.service_account_name}"
    ]
    "roles/storage.objectAdmin" = [
      "principal://iam.googleapis.com/projects/${local.project.gcp_project_number}/locations/global/workloadIdentityPools/${local.project.gcp_project}.svc.id.goog/subject/ns/${local.app_namespace}/sa/${local.service_account_name}"
    ]
    "roles/storage.admin" = [
      "principal://iam.googleapis.com/projects/${local.project.gcp_project_number}/locations/global/workloadIdentityPools/${local.project.gcp_project}.svc.id.goog/subject/ns/${local.app_namespace}/sa/${local.service_account_name}"
    ]
  }
}