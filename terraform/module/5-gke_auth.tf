module "gke_auth" {
  source = "terraform-google-modules/kubernetes-engine/google//modules/auth"

  project_id           = var.project_id
  cluster_name         = var.name
  location             = module.gke_regula.location
  use_private_endpoint = false

  depends_on = [
    module.gke_regula,
    module.project
  ]
}
