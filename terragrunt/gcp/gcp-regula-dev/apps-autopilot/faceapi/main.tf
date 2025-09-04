

variable "database_connection_string" {
  description = "PostgreSQL connection string for faceapi"
  type        = string
  sensitive   = true
}

variable "storage_bucket" {
  description = "GCS bucket name for faceapi storage"
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

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "service_account_name" {
  description = "Application Service Account"
  type        = string
}

variable "domain" {
  description = "Domain name for faceapi"
  type        = string
}

resource "kubernetes_namespace" "faceapi" {
  metadata {
    name = var.app_namespace
  }
}

resource "kubernetes_secret" "faceapi_license" {
  metadata {
    name      = "${var.project_name}-faceapi-license"
    namespace = kubernetes_namespace.faceapi.metadata[0].name
  }
  binary_data = {
    "regula.license" = filebase64(var.license_file_path)
  }
  type = "Opaque"
}

resource "kubernetes_secret" "faceapi_rds" {
  metadata {
    name      = "${var.project_name}-faceapi-rds"
    namespace = kubernetes_namespace.faceapi.metadata[0].name
  }
  data = {
    SQL_CONNECTION_STRING = var.database_connection_string
  }
  type = "Opaque"
}

resource "kubernetes_manifest" "faceapi_managed_cert" {
  manifest = {
    apiVersion = "networking.gke.io/v1"
    kind       = "ManagedCertificate"
    metadata = {
      name      = "${var.project_name}-faceapi-autopilot-cert"
      namespace = kubernetes_namespace.faceapi.metadata[0].name
    }
    spec = {
      domains = [var.domain]
    }
  }
}

resource "google_compute_global_address" "faceapi_ip" {
  project = var.project_id
  name = "${var.project_name}-faceapi-autopilot-ip"
}

resource "helm_release" "faceapi" {
  name       = "faceapi"
  repository = "https://regulaforensics.github.io/helm-charts"
  chart      = "faceapi"
  namespace  = kubernetes_namespace.faceapi.metadata[0].name

  atomic     = true
  replace    = false

  timeout    = 600

  version    = "2.1.3"


  values = [

    yamlencode({
      image = {
        tag = "latest-gpu"
      }

      nodeSelector = {
        "cloud.google.com/compute-class" = "Accelerator"
        "cloud.google.com/gke-accelerator" = "nvidia-l4"
        "cloud.google.com/gke-accelerator-count" = "1"
      }

      jobNodeSelector = {
        "cloud.google.com/machine-family" = "c4"
        "cloud.google.com/compute-class" = "Performance"
      }

      resources = {
        requests = {
          cpu = "1"
          memory = "6Gi"
          "nvidia.com/gpu" = "1"
        }
        limits = {
          memory = "8Gi"
          "nvidia.com/gpu" = "1"
        }
      }

      ingress = {
        enabled   = true
        className = "gce"
        annotations = {
          "kubernetes.io/ingress.class" = "gce"
          "kubernetes.io/ingress.global-static-ip-name" = google_compute_global_address.faceapi_ip.name
          "networking.gke.io/managed-certificates" = "${var.project_name}-faceapi-autopilot-cert"
        }
         hosts = [
          "${var.domain}"
        ]
        paths = [
          "/api/healthz",
          "/api/readyz",
          "/api/match",
          "/api/matching",
          "/api/detect",
          "/api/compare",
          "/api/faces",
          "/api/liveness/3d",
          "/api/v2/liveness",
          "/"
        ]
      }

      licenseSecretName = kubernetes_secret.faceapi_license.metadata[0].name

      config = {
        sdk = {
          liveness = {
            checkFilters = {
              config = [
                {
                  excludeChecks = ["EyesClosed"]
                  filter = {
                    platform = ["web", "ios", "android"]
                  }
                }
              ]
            }
          }
        }
        service = {
          storage = {
            type = "gcs"
          }
          database = {
            connectionStringSecretName = kubernetes_secret.faceapi_rds.metadata[0].name
          }
          detectMatch = {
            enabled = true
            selfOrigins = []
            results = {
              audit = true
              location = {
                bucket = var.storage_bucket
              }
            }
          }
          liveness = {
            enabled = true
            hideMetadata = true
            sessions = {
              location = {
                bucket = var.storage_bucket
              }
            }
          }
        }
      }

      env = [
        {
          name = "FACEAPI_THREADS"
          value = "10"
        },
        {
          name: "LD_LIBRARY_PATH"
          value: "/usr/local/nvidia/lib64:/app/extBin/unix:/app/cuda"
        }
      ]

      serviceAccount = {
        create = true
        name = var.service_account_name
      }

      lifecycle = {
        preStop = {
          exec = {
            command = ["/bin/sh", "-c", "sleep 45"]
          }
        }
      }

      autoscaling = {
        enabled = true
        minReplicas = 1
        maxReplicas = 4
        targetCPUUtilizationPercentage = 50
      }


      serviceMonitor = {
        enabled = true
        interval = "15s"
      }
    })
  ]

  depends_on = [kubernetes_secret.faceapi_license, kubernetes_secret.faceapi_rds, kubernetes_manifest.faceapi_managed_cert, google_compute_global_address.faceapi_ip]
}