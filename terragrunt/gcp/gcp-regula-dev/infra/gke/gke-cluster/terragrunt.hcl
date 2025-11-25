include "root" {
  path = find_in_parent_folders("root-gcp.hcl")
}

include "provider" {
  path = find_in_parent_folders("provider-gcp.hcl")
}

locals {
  project = read_terragrunt_config(find_in_parent_folders("project.hcl")).locals
  deploy_gpu = local.project.apps.faceapi.deploy
}

skip = local.project.gke_cluster_type != "standard"

terraform {
  source = "tfr:///terraform-google-modules/kubernetes-engine/google//.?version=38.0.1"
}

dependency "vpc" {
  config_path = "../../vpc/vpc"
  mock_outputs = {
    network_name  = local.project.gcp_project
    subnets_names = ["${local.project.gcp_project}-private"]
  }
}

inputs = {
  kubernetes_version         = "1.33.3-gke.1136000"
  project_id                 = local.project.gcp_project
  name                       = local.project.gke_cluster_name
  region                     = local.project.gcp_region
  zones      = local.project.gcp_zones
  network    = dependency.vpc.outputs.network_name
  subnetwork = dependency.vpc.outputs.subnets_names[0]

  # Enable HTTP Load Balancing addon
  disable_default_snat       = true
  enable_http_load_balancing = true

  network_policy                       = false
  filestore_csi_driver                 = false
  dns_cache                            = false
  enable_secret_manager_addon          = false
  horizontal_pod_autoscaling           = true
  gke_backup_agent_config              = false
  grant_registry_access                = true
  create_service_account               = true


  monitoring_enable_managed_prometheus = true
  monitoring_enable_observability_metrics = true
  monitoring_enable_observability_relay = true
  datapath_provider                 = "ADVANCED_DATAPATH"
  monitoring_enabled_components       = [
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

  remove_default_node_pool = true
  deletion_protection      = false
  enable_cost_allocation   = true

  ip_range_pods     = "${local.project.gcp_project}-private-pods"
  ip_range_services = "${local.project.gcp_project}-private-service"

  # Node pool configuration https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_node_pool
  node_pools = concat([
    {
      name                 = "cpu-nodepool"
      machine_type         = local.project.compute.cpu_nodepool
      autoscaling          = true
      location_policy      = "ANY"
      total_min_count      = 1
      total_max_count      = 10
      disk_size_gb         = 30
      disk_type            = "hyperdisk-balanced"
      image_type           = "COS_CONTAINERD"
      auto_repair          = true
      auto_upgrade         = true
      preemptible          = false
      enable_private_nodes = true
      max_unavailable      = 1
      max_pods_per_node    = 40
    }
  ], local.deploy_gpu ? [{
      name                 = "gpu-nodepool"
      machine_type         = local.project.compute.gpu_nodepool
      autoscaling          = true
      location_policy      = "ANY"
      spot                 = true
      total_min_count      = 1
      total_max_count      = 3
      disk_size_gb         = 100
      disk_type            = "pd-balanced"
      image_type           = "COS_CONTAINERD"
      auto_repair          = true
      auto_upgrade         = true
      preemptible          = false
      enable_private_nodes = true
      max_unavailable      = 1
      max_pods_per_node    = 40

      # GPU bits
      accelerator_type     = "nvidia-l4"
      accelerator_count    = 1
      gpu_driver_version   = "LATEST"
    }] : [])

  node_pools_oauth_scopes = {
    all = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/trace.append",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/servicecontrol",
    ]
  }

  node_pools_labels = merge({
    cpu-nodepool = {
      nodepool = "cpu-nodepool"
    }
  }, local.deploy_gpu ? {
    gpu-nodepool = {
      nodepool = "gpu-nodepool"
    }
  } : {})

  node_pools_taints = local.deploy_gpu ? {
    gpu-nodepool = [
      {
        key    = "nvidia.com/gpu"
        value  = "present"
        effect = "NO_SCHEDULE"
      }
    ]
  } : {}
}