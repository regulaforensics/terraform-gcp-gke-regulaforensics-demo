variable "database_connection_string" {
  description = "PostgreSQL connection string for docreader"
  type        = string
  sensitive   = true
}

variable "storage_bucket" {
  description = "GCS bucket name for docreader storage"
  type        = string
}

variable "cluster_name" {
  description = "GKE cluster name"
  type        = string
}

variable "cluster_location" {
  description = "GKE cluster location"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "license_file_path" {
  description = "Path to regula.license file"
  type        = string
}

variable "app_namespace" {
  description = "Application namespace"
  type        = string
}

variable "service_account_name" {
  description = "Application Service Account"
  type        = string
}

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "domain" {
  description = "Domain name for docreader"
  type        = string
}

resource "kubernetes_namespace" "docreader" {
  metadata {
    name = var.app_namespace
  }
}

resource "kubernetes_secret" "docreader_license" {
  metadata {
    name      = "${var.project_name}-docreader-license"
    namespace = kubernetes_namespace.docreader.metadata[0].name
  }
  binary_data = {
    "regula.license" = filebase64(var.license_file_path)
  }
  type = "Opaque"
}

resource "kubernetes_secret" "docreader_rds" {
  metadata {
    name      = "${var.project_name}-docreader-rds"
    namespace = kubernetes_namespace.docreader.metadata[0].name
  }
  data = {
    SQL_CONNECTION_STRING = var.database_connection_string
  }
  type = "Opaque"
}

resource "kubernetes_manifest" "docreader_managed_cert" {
  manifest = {
    apiVersion = "networking.gke.io/v1"
    kind       = "ManagedCertificate"
    metadata = {
      name      = "${var.project_name}-docreader-autopilot-cert"
      namespace = kubernetes_namespace.docreader.metadata[0].name
    }
    spec = {
      domains = [var.domain]
    }
  }
}

resource "google_compute_global_address" "docreader_ip" {
  project = var.project_id
  name = "${var.project_name}-docreader-autopilot-ip"
}

resource "helm_release" "docreader" {
  name       = "docreader"
  repository = "https://regulaforensics.github.io/helm-charts"
  chart      = "docreader"
  namespace  = kubernetes_namespace.docreader.metadata[0].name

  atomic     = true
  replace    = true
  version    = "2.2.6"

  values = [
    yamlencode({
      resources = {
        limits = {
          memory = "3Gi"
        }
        requests = {
          cpu    = "1000m"
          memory = "2Gi"
        }
      }

      lifecycle = {
        preStop = {
          exec = {
            command = ["/bin/sh", "-c", "sleep 45"]
          }
        }
      }

      nodeSelector = {
        "cloud.google.com/machine-family" = "c4"
        "cloud.google.com/compute-class" = "Performance"
      }

      licenseSecretName = kubernetes_secret.docreader_license.metadata[0].name

      ingress = {
        enabled   = true
        className = "gce"
        annotations = {
          "kubernetes.io/ingress.class" = "gce"
          "kubernetes.io/ingress.global-static-ip-name" = google_compute_global_address.docreader_ip.name
          "networking.gke.io/managed-certificates" = "${var.project_name}-docreader-autopilot-cert"
        }
        hosts = [
          "${var.domain}"
        ]
        paths = [
          "/api/ping",
          "/api/healthz",
          "/api/readyz",
          "/api/process",
          "/api/v2/transaction",
          "/api/v2/tag",
          "/"
        ]
      }

      config = {
        service = {
          storage = {
            type = "gcs"
          }
          database = {
            connectionStringSecretName = kubernetes_secret.docreader_rds.metadata[0].name
          }
          processing = {
            results = {
              location = {
                bucket = var.storage_bucket
              }
            }
          }
          sessionApi = {
            enabled = true
            transactions = {
              location = {
                bucket = var.storage_bucket
              }
            }
          }
        }
      }

      serviceAccount = {
        create = true
        name   = var.service_account_name
      }

      podDisruptionBudget = {
        enabled = true
      }

      autoscaling = {
        enabled     = true
        minReplicas = 1
        maxReplicas = 4
      }

      serviceMonitor = {
        enabled = true
        interval = "15s"
      }
    })
  ]

  depends_on = [kubernetes_secret.docreader_license, kubernetes_secret.docreader_rds, kubernetes_manifest.docreader_managed_cert, google_compute_global_address.docreader_ip]
}