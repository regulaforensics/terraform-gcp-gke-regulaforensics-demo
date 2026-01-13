locals {
  remote_overwrite = try(read_terragrunt_config("remote_overwrite.hcl").locals, null)
  project          = read_terragrunt_config(find_in_parent_folders("project-aws.hcl")).locals
}

remote_state {
  backend = "s3"
  generate = {
    path      = "_backend.tf"
    if_exists = "overwrite"
  }

  config = {
    bucket         = "terraform-${local.project.project_name}-${local.project.aws_account_id}"
    key            = try(local.remote_overwrite.s3_key, "projects/${path_relative_to_include()}.tfstate")
    region         = local.project.aws_region
    encrypt        = true
    use_lockfile   = true
    dynamodb_table = "terraform-${local.project.project_name}-locks"
  }
}