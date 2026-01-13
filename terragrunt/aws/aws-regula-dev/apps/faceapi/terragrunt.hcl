terraform {
  source = "."
}

include "root" {
  path = find_in_parent_folders("root-aws.hcl")
}

include "aws_provider" {
  path = find_in_parent_folders("provider-aws.hcl")
}

include "k8s_provider" {
  path = find_in_parent_folders("provider-k8s-aws.hcl")
}

dependency "eks" {
  config_path = "../../infra/eks/eks-cluster"
  mock_outputs = {
    cluster_name = "mock-cluster"
    cluster_endpoint = "https://mock-endpoint.eks.us-west-2.amazonaws.com"
  }
}

dependency "s3" {
  config_path = "../../infra/s3/faceapi"
  mock_outputs = {
    s3_bucket_id = "mock-bucket"
  }
}

dependency "rds" {
  config_path = "../../infra/rds"
  mock_outputs = {
    db_instance_endpoint = "mock-endpoint.rds.amazonaws.com"
    db_instance_port = 5432
    master_user_secret_arn = "arn:aws:secretsmanager:us-west-2:123456789012:secret:mock-secret"
  }
}

locals {
  project  = read_terragrunt_config(find_in_parent_folders("project-aws.hcl")).locals
  app_name = local.project.apps.faceapi.name
  deploy   = local.project.apps.faceapi.deploy
}

skip = !local.deploy

inputs = {
  database_endpoint          = dependency.rds.outputs.db_instance_endpoint
  database_port              = dependency.rds.outputs.db_instance_port
  database_secret_arn        = dependency.rds.outputs.master_user_secret_arn
  storage_bucket             = dependency.s3.outputs.s3_bucket_id
  cluster_name               = dependency.eks.outputs.cluster_name
  cluster_endpoint           = dependency.eks.outputs.cluster_endpoint
  project_name               = local.project.project_name
  aws_region                 = local.project.aws_region
  app_namespace              = "${local.app_name}-${local.project.project_env}"
  domain                     = "aws-${local.app_name}-${local.project.project_env}.${local.project.domain}"
  service_account_name       = "${local.app_name}-${local.project.project_env}"
  license_file_path          = "${get_parent_terragrunt_dir("root")}/regula.license"
  chart_version              = local.project.apps.faceapi.chart_version
}