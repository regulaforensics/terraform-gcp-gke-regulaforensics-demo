locals {
  remote_overwrite = try(read_terragrunt_config("remote_overwrite.hcl").locals, null)
  project          = read_terragrunt_config(find_in_parent_folders("project.hcl")).locals
}

remote_state {
  backend = "gcs"
  generate = {
    path      = "_backend.tf"
    if_exists = "overwrite"
  }

  config = {
    bucket   = "terraform-${local.project.gcp_project}"
    prefix   = try(local.remote_overwrite.s3_key, "projects/${path_relative_to_include()}.tfstate")
    project  = local.project.gcp_project
    location = local.project.gcp_region
  }
}