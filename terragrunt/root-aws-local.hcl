locals {
  remote_overwrite = try(read_terragrunt_config("remote_overwrite.hcl").locals, null)
  project          = read_terragrunt_config(find_in_parent_folders("project-aws.hcl")).locals
}

# Use local backend for testing
remote_state {
  backend = "local"
  generate = {
    path      = "_backend.tf"
    if_exists = "overwrite"
  }

  config = {
    path = "terraform.tfstate"
  }
}