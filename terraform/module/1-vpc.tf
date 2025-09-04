module "vpc" {
  source  = "terraform-google-modules/network/google"
  version = "~> 6.0"

  project_id              = var.project_id
  network_name            = var.name
  routing_mode            = "REGIONAL"
  auto_create_subnetworks = false

  subnets = [
    {
      subnet_private_access = var.subnet_private_access
      subnet_name           = "private-subnet"
      subnet_ip             = var.subnet_ip_range
      subnet_region         = var.region
    }
  ]

  secondary_ranges = {
    private-subnet = var.secondary_ip_ranges
  }

  depends_on = [
    module.project
  ]
}
