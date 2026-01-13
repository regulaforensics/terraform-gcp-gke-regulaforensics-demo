locals {
  # Core project settings
  aws_account_id     = "894602450013" # Your AWS Account ID
  aws_region         = "us-west-2"
  aws_zones          = [
    "us-west-2a",
    "us-west-2b",
    "us-west-2c"
  ]
  project_name       = "regula-demo" # Replace with your project name
  project_env        = "dev"
  
  # App configurations
  apps = {
    docreader = {
      name          = "docreader"
      namespace     = "docreader"
      chart_version = "2.3.0"
      deploy        = true
    }
    faceapi = {
      name          = "faceapi" 
      namespace     = "faceapi"
      deploy        = true
      chart_version = "2.2.0"
    }
  }
  
  # Infrastructure settings
  eks_cluster_name = "${local.project_name}-${local.project_env}-eks"
  
  # Resource sizing
  compute = {
    cpu_nodegroup = "m5.large"
    gpu_nodegroup = "g4dn.xlarge"
    db_instance   = "db.t3.medium"
  }
  
  domain            = "example.com" # Replace with your domain
  license_file_path = "regula.license"
}