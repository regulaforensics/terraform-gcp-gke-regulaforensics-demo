# Technology Stack

## Infrastructure as Code

- **Terragrunt**: Primary IaC tool for managing Terraform configurations with DRY principles
- **Terraform**: Underlying infrastructure provisioning engine (>= 1.0)
- **Helm**: Kubernetes package manager for application deployment (>= 3.0)

## Cloud Platforms

### Google Cloud Platform (GCP)
- **GKE**: Google Kubernetes Engine (Standard and Autopilot modes)
- **Cloud SQL**: PostgreSQL database service
- **Cloud Storage**: Object storage buckets
- **VPC**: Custom networking with Private Service Access

### Amazon Web Services (AWS)
- **EKS**: Elastic Kubernetes Service
- **RDS**: PostgreSQL database service
- **S3**: Object storage buckets
- **VPC**: Custom networking with NAT Gateway and VPC Endpoints

## Application Stack

- **Kubernetes**: Container orchestration platform
- **PostgreSQL**: Primary database for both DocReader and FaceAPI
- **Regula Forensics**: Licensed applications (DocReader 2.3.0, FaceAPI 2.2.0)

## Development Tools

- **kubectl**: Kubernetes command-line tool
- **Google Cloud SDK**: GCP CLI and authentication
- **AWS CLI**: AWS command-line interface
- **PostgreSQL client (psql)**: Database operations

## Common Commands

### Initial Setup
```bash
# GCP Authentication
gcloud auth login
gcloud auth application-default login
gcloud config set project YOUR_PROJECT_ID

# AWS Authentication
aws configure
aws eks update-kubeconfig --region REGION --name CLUSTER_NAME
```

### Deployment Commands
```bash
# Full deployment (all components)
terragrunt apply --all

# Step-by-step deployment
terragrunt apply --all --terragrunt-include-dir infra/vpc
terragrunt apply --all --terragrunt-include-dir infra/gke  # or infra/eks
terragrunt apply --terragrunt-working-dir infra/gsql      # or infra/rds
terragrunt apply --all --terragrunt-include-dir infra/gcs # or infra/s3
terragrunt apply --all --terragrunt-include-dir apps

# Individual component deployment
terragrunt apply --terragrunt-working-dir path/to/component
```

### Management Commands
```bash
# Planning and validation
terragrunt plan --all
terragrunt validate --all
terragrunt graph-dependencies

# Monitoring and troubleshooting
kubectl get pods -n NAMESPACE
kubectl logs -n NAMESPACE deployment/APP_NAME
kubectl cluster-info
kubectl get nodes -o wide

# Cleanup
terragrunt destroy --all --terragrunt-include-dir apps
terragrunt destroy --all --terragrunt-include-dir infra
```

### Terragrunt-Specific Commands
```bash
# Show all outputs
terragrunt output --all

# Run specific commands in all modules
terragrunt run-all plan
terragrunt run-all apply
terragrunt run-all destroy
```

## Configuration Management

- **HCL**: HashiCorp Configuration Language for Terragrunt/Terraform
- **YAML**: Kubernetes manifests and Helm values
- **License file**: `regula.license` required in terragrunt/ directory

## Version Requirements

- Terraform >= 1.0 (recommended >= 1.13)
- Terragrunt >= 0.45 (recommended >= 0.8)
- Helm >= 3.0
- kubectl (compatible with target Kubernetes version)
- Google Cloud SDK (latest)
- AWS CLI v2 (latest)