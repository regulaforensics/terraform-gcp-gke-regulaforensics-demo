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
  source = "tfr:///terraform-aws-modules/s3-bucket/aws?version=5.9.1"
}

inputs = {
  bucket = "${local.project.project_name}-${local.project.project_env}-faceapi"

  # Versioning
  versioning = {
    enabled = true
  }

  # Server side encryption
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  # Block public access
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  # Lifecycle configuration
  lifecycle_configuration = {
    rule = {
      id     = "delete_old_versions"
      status = "Enabled"

      noncurrent_version_expiration = {
        noncurrent_days = 30
      }

      abort_incomplete_multipart_upload = {
        days_after_initiation = 7
      }
    }
  }

  tags = {
    Name        = "${local.project.project_name}-${local.project.project_env}-faceapi"
    Application = "faceapi"
  }
}