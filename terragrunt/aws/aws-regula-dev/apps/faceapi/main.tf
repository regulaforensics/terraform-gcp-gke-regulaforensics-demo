variable "database_endpoint" {
  description = "RDS endpoint for faceapi"
  type        = string
}

variable "database_port" {
  description = "RDS port"
  type        = number
  default     = 5432
}

variable "database_secret_arn" {
  description = "ARN of the RDS master user secret"
  type        = string
}

variable "storage_bucket" {
  description = "S3 bucket name for faceapi storage"
  type        = string
}

variable "cluster_endpoint" {
  description = "EKS cluster endpoint"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
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

variable "domain" {
  description = "Domain name for faceapi"
  type        = string
}

variable "chart_version" {
  description = "Helm chart version for faceapi"
  type        = string
  default     = "2.2.0"
}

# Get current AWS account ID
data "aws_caller_identity" "current" {}

# Get RDS credentials from Secrets Manager
data "aws_secretsmanager_secret_version" "rds_credentials" {
  secret_id = var.database_secret_arn
}

locals {
  rds_creds = jsondecode(data.aws_secretsmanager_secret_version.rds_credentials.secret_string)
  database_connection_string = "postgresql://${local.rds_creds.username}:${local.rds_creds.password}@${var.database_endpoint}:${var.database_port}/faceapi"
}

# Create namespace
resource "kubernetes_namespace" "faceapi" {
  metadata {
    name = var.app_namespace
  }
}

# IAM role for service account (IRSA)
resource "aws_iam_role" "faceapi_service_account" {
  name = "${var.project_name}-faceapi-service-account"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(var.cluster_endpoint, "https://", "")}"
        }
        Condition = {
          StringEquals = {
            "${replace(var.cluster_endpoint, "https://", "")}:sub" = "system:serviceaccount:${var.app_namespace}:${var.service_account_name}"
            "${replace(var.cluster_endpoint, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}

# IAM policy for S3 access
resource "aws_iam_role_policy" "faceapi_s3_policy" {
  name = "${var.project_name}-faceapi-s3-policy"
  role = aws_iam_role.faceapi_service_account.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.storage_bucket}",
          "arn:aws:s3:::${var.storage_bucket}/*"
        ]
      }
    ]
  })
}

# Kubernetes service account with IRSA annotation
resource "kubernetes_service_account" "faceapi" {
  metadata {
    name      = var.service_account_name
    namespace = kubernetes_namespace.faceapi.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.faceapi_service_account.arn
    }
  }
}

# License secret
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

# Database connection secret
resource "kubernetes_secret" "faceapi_rds" {
  metadata {
    name      = "${var.project_name}-faceapi-rds"
    namespace = kubernetes_namespace.faceapi.metadata[0].name
  }
  data = {
    SQL_CONNECTION_STRING = local.database_connection_string
  }
  type = "Opaque"
}

# Data sources for VPC and subnets
data "aws_vpc" "main" {
  filter {
    name   = "tag:Name"
    values = ["${var.project_name}-${split("-", var.app_namespace)[1]}"]
  }
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }
  
  filter {
    name   = "tag:kubernetes.io/role/elb"
    values = ["1"]
  }
}

# Helm release for faceapi
resource "helm_release" "faceapi" {
  name       = "faceapi"
  replace    = true
  repository = "https://regulaforensics.github.io/helm-charts"
  chart      = "faceapi"
  namespace  = kubernetes_namespace.faceapi.metadata[0].name

  atomic  = true
  version = var.chart_version

  values = [
    yamlencode({
      resources = {
        limits = {
          memory = "4Gi"
        }
        requests = {
          cpu    = "1000m"
          memory = "3Gi"
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
        nodepool = "gpu-nodepool"
      }

      tolerations = [
        {
          key    = "nvidia.com/gpu"
          value  = "true"
          effect = "NoSchedule"
        }
      ]

      licenseSecretName = kubernetes_secret.faceapi_license.metadata[0].name

      ingress = {
        enabled   = true
        className = "alb"
        annotations = {
          "kubernetes.io/ingress.class" = "alb"
          "alb.ingress.kubernetes.io/scheme" = "internet-facing"
          "alb.ingress.kubernetes.io/target-type" = "ip"
          "alb.ingress.kubernetes.io/listen-ports" = "[{\"HTTP\": 80}, {\"HTTPS\": 443}]"
          "alb.ingress.kubernetes.io/ssl-redirect" = "443"
        }
        hosts = [
          var.domain
        ]
        paths = [
          "/api/ping",
          "/api/healthz",
          "/api/readyz",
          "/api/face",
          "/api/v2/face",
          "/"
        ]
      }

      config = {
        service = {
          storage = {
            type = "s3"
          }
          database = {
            connectionStringSecretName = kubernetes_secret.faceapi_rds.metadata[0].name
          }
          processing = {
            results = {
              location = {
                bucket = var.storage_bucket
                region = var.aws_region
              }
            }
          }
        }
      }

      serviceAccount = {
        create = false
        name   = kubernetes_service_account.faceapi.metadata[0].name
      }

      podDisruptionBudget = {
        enabled = true
      }

      topologySpreadConstraints = [
        {
          maxSkew           = 1
          topologyKey       = "topology.kubernetes.io/zone"
          whenUnsatisfiable = "DoNotSchedule"
          labelSelector = {
            matchLabels = {
              "nodepool": "gpu-nodepool"
            }
          }
          matchLabelKeys = ["pod-template-hash"]
        }
      ]

      autoscaling = {
        enabled     = true
        minReplicas = 0
        maxReplicas = 3
      }

      serviceMonitor = {
        enabled  = true
        interval = "15s"
      }
    })
  ]

  depends_on = [
    kubernetes_secret.faceapi_license,
    kubernetes_secret.faceapi_rds,
    kubernetes_service_account.faceapi,
    aws_iam_role_policy.faceapi_s3_policy
  ]
}