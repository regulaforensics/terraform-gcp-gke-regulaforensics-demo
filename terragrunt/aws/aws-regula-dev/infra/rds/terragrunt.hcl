include "root" {
  path = find_in_parent_folders("root-aws.hcl")
}

include "provider" {
  path = find_in_parent_folders("provider-aws.hcl")
}

locals {
  project = read_terragrunt_config(find_in_parent_folders("project-aws.hcl")).locals
  deploy_docreader = local.project.apps.docreader.deploy
  deploy_faceapi = local.project.apps.faceapi.deploy
}

terraform {
  source = "tfr:///terraform-aws-modules/rds/aws?version=6.13.1"
}

dependency "vpc" {
  config_path = "../vpc/vpc"
  mock_outputs = {
    vpc_id = "vpc-12345678"
    database_subnets = ["subnet-12345678", "subnet-87654321"]
    vpc_cidr_block = "10.0.0.0/16"
  }
}

inputs = {
  identifier = "${local.project.project_name}-${local.project.project_env}"

  # Database
  engine               = "postgres"
  engine_version       = "16.4"
  family               = "postgres16"
  major_engine_version = "16"
  instance_class       = local.project.compute.db_instance

  allocated_storage     = 20
  max_allocated_storage = 100

  # Database name and credentials
  db_name  = "postgres"
  username = "admin"
  manage_master_user_password = true

  port = 5432

  # Subnet and security groups - reference outputs from dependencies
  create_db_subnet_group = true
  subnet_ids            = dependency.vpc.outputs.database_subnets
  vpc_security_group_ids = []

  # Backup and maintenance
  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "Mon:04:00-Mon:05:00"

  # Enhanced monitoring
  monitoring_interval    = 60
  monitoring_role_name   = "${local.project.project_name}-rds-monitoring-role"
  create_monitoring_role = true

  # Deletion protection
  deletion_protection = false
  skip_final_snapshot = true

  tags = {
    Name = "${local.project.project_name}-${local.project.project_env}"
  }
}