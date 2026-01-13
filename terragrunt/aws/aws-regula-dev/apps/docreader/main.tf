variable "database_endpoint" {
  description = "RDS endpoint for docreader"
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
  description = "S3 bucket name for docreader storage"
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
  description = "Domain name for docreader"
  type        = string
}

variable "chart_version" {
  description = "Helm chart version for docreader"
  type        = string
  default     = "2.3.0"
}

# Get current AWS account ID
data "aws_caller_identity" "current" {}

# Get RDS credentials from Secrets Manager (skip if using mock data)
data "aws_secretsmanager_secret_version" "rds_credentials" {
  count     = strcontains(var.database_secret_arn, "mock-secret") ? 0 : 1
  secret_id = var.database_secret_arn
}

locals {
  # Use mock credentials when secret ARN contains "mock-secret"
  rds_creds = strcontains(var.database_secret_arn, "mock-secret") ? {
    username = "mockuser"
    password = "mockpassword"
  } : jsondecode(data.aws_secretsmanager_secret_version.rds_credentials[0].secret_string)
  
  database_connection_string = "postgresql://${local.rds_creds.username}:${local.rds_creds.password}@${var.database_endpoint}:${var.database_port}/docreader"
}

# Create namespace
resource "kubernetes_namespace" "docreader" {
  metadata {
    name = var.app_namespace
  }
}

# IAM role for service account (IRSA)
resource "aws_iam_role" "docreader_service_account" {
  name = "${var.project_name}-docreader-service-account"

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
resource "aws_iam_role_policy" "docreader_s3_policy" {
  name = "${var.project_name}-docreader-s3-policy"
  role = aws_iam_role.docreader_service_account.id

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
resource "kubernetes_service_account" "docreader" {
  metadata {
    name      = var.service_account_name
    namespace = kubernetes_namespace.docreader.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.docreader_service_account.arn
    }
  }
}

# License secret
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

# Database connection secret
resource "kubernetes_secret" "docreader_rds" {
  metadata {
    name      = "${var.project_name}-docreader-rds"
    namespace = kubernetes_namespace.docreader.metadata[0].name
  }
  data = {
    SQL_CONNECTION_STRING = local.database_connection_string
  }
  type = "Opaque"
}

# Application Load Balancer for ingress (skip if using mock VPC)
resource "aws_lb" "docreader" {
  count              = contains(data.aws_vpc.main.id, "vpc-") ? 1 : 0
  name               = "${var.project_name}-docreader-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb[0].id]
  subnets            = data.aws_subnets.public.ids

  enable_deletion_protection = false

  tags = {
    Name = "${var.project_name}-docreader-alb"
  }
}

# Security group for ALB
resource "aws_security_group" "alb" {
  count       = contains(data.aws_vpc.main.id, "vpc-") ? 1 : 0
  name_prefix = "${var.project_name}-docreader-alb-"
  vpc_id      = data.aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-docreader-alb"
  }
}

# Data sources for VPC and subnets
data "aws_vpc" "main" {
  id = "vpc-0c75f3ae431b28c8d"
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

# Helm release for docreader
resource "helm_release" "docreader" {
  name       = "docreader"
  replace    = true
  repository = "https://regulaforensics.github.io/helm-charts"
  chart      = "docreader"
  namespace  = kubernetes_namespace.docreader.metadata[0].name

  atomic  = true
  version = var.chart_version

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
        nodepool = "cpu-nodepool"
      }

      licenseSecretName = kubernetes_secret.docreader_license.metadata[0].name

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
          "/api/process",
          "/api/v2/transaction",
          "/api/v2/tag",
          "/"
        ]
      }

      config = {
        service = {
          storage = {
            type = "s3"
          }
          database = {
            connectionStringSecretName = kubernetes_secret.docreader_rds.metadata[0].name
          }
          processing = {
            results = {
              location = {
                bucket = var.storage_bucket
                region = var.aws_region
              }
            }
          }
          sessionApi = {
            enabled = true
            transactions = {
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
        name   = kubernetes_service_account.docreader.metadata[0].name
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
              "nodepool": "cpu-nodepool"
            }
          }
          matchLabelKeys = ["pod-template-hash"]
        }
      ]

      autoscaling = {
        enabled     = true
        minReplicas = 1
        maxReplicas = 4
      }

      serviceMonitor = {
        enabled  = true
        interval = "15s"
      }
    })
  ]

  depends_on = [
    kubernetes_secret.docreader_license,
    kubernetes_secret.docreader_rds,
    kubernetes_service_account.docreader,
    aws_iam_role_policy.docreader_s3_policy
  ]
}