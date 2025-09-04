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
  source = "tfr:///terraform-google-modules/network/google//.?version=11.1.1"
}

dependency "apis" {
      config_path = "../../apis"
  
      mock_outputs = {
          apis_output = "mock-apis-output"
      }
  }

inputs = {
  project_id   = local.project.gcp_project
  network_name = local.project.gcp_project
  mtu          = 1460
  routing_mode = "GLOBAL"

  subnets = [
    {
      subnet_name           = "${local.project.gcp_project}-private"
      subnet_ip             = "10.20.0.0/16"
      subnet_region         = local.project.gcp_region
      subnet_private_access = true
      subnet_flow_logs      = true
      description           = "Only internal inbound traffic"
    },
    {
      subnet_name           = "${local.project.gcp_project}-public"
      subnet_ip             = "10.22.0.0/19"
      subnet_region         = local.project.gcp_region
      subnet_private_access = false
      subnet_flow_logs      = true
    }
  ]

  secondary_ranges = {
    "${local.project.gcp_project}-private" = [
      {
        range_name    = "${local.project.gcp_project}-private-pods"
        ip_cidr_range = "10.21.0.0/17"
      },
      {
        range_name    = "${local.project.gcp_project}-private-infra"
        ip_cidr_range = "10.21.128.0/20"
      },
      {
        range_name    = "${local.project.gcp_project}-private-db"
        ip_cidr_range = "10.21.144.0/23"
      },
      {
        range_name    = "${local.project.gcp_project}-private-service"
        ip_cidr_range = "172.21.0.0/22"
      }
    ]
  }

  routes = [
    {
      name              = "nat-default-route"
      description       = "Default route for private subnets"
      destination_range = "0.0.0.0/0"
      next_hop_internet = true
    }
  ]
}