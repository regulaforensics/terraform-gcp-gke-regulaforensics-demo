generate "provider-kubernetes" {
  path      = "_provider_kubernetes.tf"
  if_exists = "overwrite"
  contents  = <<EOF

terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.0.2"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.38"
    }
  }
}

data "google_client_config" "default" {}

data "google_container_cluster" "gke_cluster" {
  name     = var.cluster_name
  location = var.cluster_location
  project  = var.project_id
}

provider "kubernetes" {
  host                   = "https://$${data.google_container_cluster.gke_cluster.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(data.google_container_cluster.gke_cluster.master_auth.0.cluster_ca_certificate)
}

provider "helm" {
  kubernetes = {
    host  = "https://$${data.google_container_cluster.gke_cluster.endpoint}"
    token = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(
    data.google_container_cluster.gke_cluster.master_auth[0].cluster_ca_certificate,)
    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "gke-gcloud-auth-plugin"
    }
  }
}
EOF
}