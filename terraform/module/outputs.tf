output "cluster_name" {
  description = "Cluster name"
  value       = module.gke_regula.name
}

output "config" {
  description = "Cluster config"
  value       = module.gke_auth.kubeconfig_raw
}
