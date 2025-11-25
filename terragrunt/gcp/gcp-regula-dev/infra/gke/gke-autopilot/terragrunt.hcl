include "root" {
  path = find_in_parent_folders("root-gcp.hcl")
}

include "provider" {
  path = find_in_parent_folders("provider-gcp.hcl")
}

locals {
  project = read_terragrunt_config(find_in_parent_folders("project.hcl")).locals
}

skip = local.project.gke_cluster_type != "autopilot"

terraform {
  source = "tfr:///terraform-google-modules/kubernetes-engine/google//modules/beta-autopilot-public-cluster?version=38.0.1"
}

dependency "vpc" {
  config_path = "../../vpc/vpc"
  mock_outputs = {
    network_name  = local.project.gcp_project
    subnets_names = ["${local.project.gcp_project}-private"]
  }
}

inputs = {
  project_id = local.project.gcp_project
  name       = "${local.project.gke_cluster_name}-autopilot"
  region     = local.project.gcp_region
  network    = dependency.vpc.outputs.network_name
  subnetwork = dependency.vpc.outputs.subnets_names[0]

  ip_range_pods     = "${local.project.gcp_project}-private-pods"
  ip_range_services = "${local.project.gcp_project}-private-service"

  enable_cost_allocation          = true
  deletion_protection             = false
  enable_vertical_pod_autoscaling = true
  horizontal_pod_autoscaling      = true
  grant_registry_access           = true
  http_load_balancing             = true

  monitoring_enabled_components = [
    "SYSTEM_COMPONENTS",
    "APISERVER",
    "SCHEDULER",
    "CONTROLLER_MANAGER",
    "STORAGE",
    "HPA",
    "POD",
    "DAEMONSET",
    "DEPLOYMENT",
    "STATEFULSET",
    "KUBELET",
    "CADVISOR",
    "DCGM",
    "JOBSET",
  ]

  logging_enabled_components = [
    "SYSTEM_COMPONENTS",
    "APISERVER",
    "CONTROLLER_MANAGER",
    "SCHEDULER",
    "WORKLOADS"
  ]
}