include "root" {
  path = find_in_parent_folders("root-gcp.hcl")
}

include "provider" {
  path = find_in_parent_folders("provider-gcp.hcl")
}

locals {
  project = read_terragrunt_config(find_in_parent_folders("project.hcl")).locals
  deploy_docreader = local.project.apps.docreader.deploy
  deploy_faceapi = local.project.apps.faceapi.deploy
}

terraform {
  source = "tfr:///terraform-google-modules/sql-db/google//modules/postgresql//.?version=26.1.0"
}


dependency "vpc" {
  config_path = "../vpc/vpc"
  mock_outputs = {
    network_self_link = "projects/${local.project.gcp_project}/global/networks/${local.project.gcp_project}"
  }
}

dependency "vpc_psa" {
  config_path = "../vpc/vpc-psa"
  mock_outputs = {
    google_compute_global_address_name = "mock-psa-range"
  }
}

inputs = {
  name                 = "${local.project.project_name}-${local.project.project_env}"
  random_instance_name = false
  project_id           = local.project.gcp_project
  database_version     = "POSTGRES_16"
  region               = local.project.gcp_region

  // Master configurations
  edition           = "ENTERPRISE"
  tier              = local.project.compute.db_size
  zone              = local.project.gcp_zones[0]
  availability_type = "ZONAL"

  ip_configuration = {
    ipv4_enabled                                  = true
    private_network                               = dependency.vpc.outputs.network_self_link
    ssl_mode                                      = "ALLOW_UNENCRYPTED_AND_ENCRYPTED"
    enable_private_path_for_google_cloud_services = false
    allocated_ip_range                            = dependency.vpc_psa.outputs.google_compute_global_address_name
  }

  user_name = "admin"

  password_validation_policy_config = {
    min_length = 8
    complexity = "COMPLEXITY_UNSPECIFIED"
  }

  additional_databases = concat(
    local.deploy_docreader ? [{
      name      = "docreader"
      charset   = "UTF8"
      collation = "en_US.UTF8"
    }] : [],
    local.deploy_faceapi ? [{
      name      = "faceapi"
      charset   = "UTF8"
      collation = "en_US.UTF8"
    }] : []
  )

  additional_users = concat(
    local.deploy_docreader ? [{
      name            = "docreader"
      password        = ""
      random_password = true
    }] : [],
    local.deploy_faceapi ? [{
      name            = "faceapi"
      password        = ""
      random_password = true
    }] : []
  )

  deletion_protection      = false
  retain_backups_on_delete = true

  backup_configuration = {
    enabled                        = true
    start_time                     = "00:00"
    location                       = "us"
    point_in_time_recovery_enabled = true
    transaction_log_retention_days = 7
    retained_backups               = 7
    retention_unit                 = "COUNT"
  }
}