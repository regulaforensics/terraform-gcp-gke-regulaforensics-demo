include "root" {
  path = find_in_parent_folders("root-aws.hcl")
}

include "provider" {
  path = find_in_parent_folders("provider-aws.hcl")
}

locals {
  project = read_terragrunt_config(find_in_parent_folders("project-aws.hcl")).locals
}

terraform {
  source = "tfr:///terraform-aws-modules/vpc/aws//modules/vpc-endpoints?version=6.5.1"
}

dependency "vpc" {
  config_path = "../vpc"
  mock_outputs = {
    vpc_id = "vpc-12345678"
    private_subnets = ["subnet-12345678", "subnet-87654321"]
    vpc_cidr_block = "10.0.0.0/16"
    private_route_table_ids = ["rtb-12345678", "rtb-87654321"]
    public_route_table_ids = ["rtb-12345679"]
  }
}

inputs = {
  vpc_id = dependency.vpc.outputs.vpc_id
  
  # Create security group for VPC endpoints
  create_security_group = true
  security_group_name_prefix = "${local.project.project_name}-vpc-endpoints-"
  security_group_description = "Security group for VPC endpoints"
  
  security_group_rules = {
    ingress_https = {
      description = "HTTPS from VPC"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = [dependency.vpc.outputs.vpc_cidr_block]
    }
  }
  
  endpoints = {
    s3 = {
      service = "s3"
      service_type = "Gateway"
      route_table_ids = dependency.vpc.outputs.private_route_table_ids
      tags = { Name = "${local.project.project_name}-s3-endpoint" }
    }
    
    ecr_api = {
      service             = "ecr.api"
      vpc_endpoint_type   = "Interface"
      subnet_ids          = dependency.vpc.outputs.private_subnets
      tags = { Name = "${local.project.project_name}-ecr-api-endpoint" }
    }
    
    ecr_dkr = {
      service             = "ecr.dkr"
      vpc_endpoint_type   = "Interface"
      subnet_ids          = dependency.vpc.outputs.private_subnets
      tags = { Name = "${local.project.project_name}-ecr-dkr-endpoint" }
    }
    
    ec2 = {
      service             = "ec2"
      vpc_endpoint_type   = "Interface"
      subnet_ids          = dependency.vpc.outputs.private_subnets
      tags = { Name = "${local.project.project_name}-ec2-endpoint" }
    }
  }
}