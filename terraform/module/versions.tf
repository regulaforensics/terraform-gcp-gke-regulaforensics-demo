terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.51.0, < 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.10"
    }
  }
  required_version = ">= 1.0"
}
