locals {
  # Core project settings
  gcp_project_number = ""
  gcp_project        = ""
  gcp_region         = "europe-west3"
  gcp_zones          = [
    "europe-west3-a",
    "europe-west3-b",
    "europe-west3-c"
  ]
  project_name       = ""
  project_env        = "dev"
  
  # App configurations
  apps = {
    docreader = {
      name      = "docreader"
      namespace = "docreader"
      deploy    = true
    }
    faceapi = {
      name      = "faceapi" 
      namespace = "faceapi"
      deploy    = true
    }
  }
  
  # Infrastructure settings
  gke_cluster_name = "${local.project_name}-${local.project_env}"
  gke_cluster_type = "standard" # "standard" or "autopilot"
  
  # Resource sizing
  compute = {
    cpu_nodepool = "n4-standard-2"
    gpu_nodepool = "g2-standard-4"
    db_size      = "db-custom-1-3840"
  }
  
  domain            = "regula.app"
  license_file_path = "regula.license"
}
