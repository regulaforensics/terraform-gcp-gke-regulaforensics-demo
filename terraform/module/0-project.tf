module "project" {
  source                      = "terraform-google-modules/project-factory/google//modules/project_services"
  version                     = "~>14.2"
  project_id                  = var.project_id
  disable_services_on_destroy = false
  activate_apis = [
    "compute.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "container.googleapis.com",
    "iam.googleapis.com"
  ]
}

data "google_project" "project" {
  project_id = var.project_id
}
