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
  source = "tfr:///terraform-aws-modules/vpc/aws?version=6.5.1"
}

inputs = {
  name = "${local.project.project_name}-${local.project.project_env}"
  cidr = "10.0.0.0/16"

  azs             = local.project.aws_zones
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  database_subnets = ["10.0.201.0/24", "10.0.202.0/24", "10.0.203.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = false
  enable_dns_hostnames = true
  enable_dns_support = true

  # EKS specific tags
  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
    "kubernetes.io/cluster/${local.project.eks_cluster_name}" = "shared"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/cluster/${local.project.eks_cluster_name}" = "shared"
  }

  tags = {
    Name = "${local.project.project_name}-${local.project.project_env}"
  }
}