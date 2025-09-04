module "gke_cluster" {
  source                     = "./module"
  project_id                 = var.project_id
  region                     = var.region
  regional                   = var.regional
  zones                      = var.zones
  name                       = var.name
  master_authorized_networks = var.master_authorized_networks
  enable_private_endpoint    = var.enable_private_endpoint
  enable_private_nodes       = var.enable_private_nodes
  subnet_private_access      = var.subnet_private_access
  subnet_ip_range            = var.subnet_ip_range
  secondary_ip_ranges        = var.secondary_ip_ranges
  node_count                 = var.node_count
  disk_size_gb               = var.disk_size_gb
  disk_type                  = var.disk_type
  machine_type               = var.machine_type
  spot                       = var.spot
  enable_docreader           = var.enable_docreader
  docreader_values           = var.docreader_values
  docreader_license          = var.docreader_license
  enable_faceapi             = var.enable_faceapi
  faceapi_values             = var.faceapi_values
  face_api_license           = var.face_api_license
}

