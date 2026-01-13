locals {
  project = read_terragrunt_config(find_in_parent_folders("project-aws.hcl")).locals
}

generate "provider-aws" {
  path      = "_provider_aws.tf"
  if_exists = "overwrite"
  contents  = <<EOF

provider "aws" {
  region = "${local.project.aws_region}"

  default_tags {
    tags = {
      Project     = "${local.project.project_name}"
      Environment = "${local.project.project_env}"
      ManagedBy   = "terraform"
    }
  }
}

EOF
}