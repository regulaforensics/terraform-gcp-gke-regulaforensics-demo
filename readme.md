# GCP GKE Regula Forensics Demo

This repository provides a **Terragrunt configuration** for deploying Regula Forensics applications (DocReader and FaceAPI) on Google Kubernetes Engine (GKE) with production-grade infrastructure management.

## Architecture Overview

The infrastructure deploys:
- **GKE Cluster**: Private Kubernetes cluster with CPU and GPU node pools
- **VPC Network**: Custom VPC with private subnets and NAT gateway
- **Cloud SQL**: PostgreSQL database for application data
- **Cloud Storage**: GCS buckets for application storage
- **Helm Applications**: DocReader and FaceAPI services

## Project Structure

```
terragrunt/                   # Terragrunt configuration
├── project.hcl           # Central configuration
├── root-gcp.hcl         # Remote state configuration
├── provider-gcp.hcl     # GCP provider configuration
├── provider-k8s-gcp.hcl # Kubernetes provider configuration
├── regula.license       # License file
├── README.md            # Terragrunt documentation
└── gcp/gcp-regula-dev/
    ├── infra/           # Infrastructure components
    │   ├── apis/        # API enablement
    │   ├── vpc/         # VPC, NAT, PSA
    │   │   ├── vpc/     # VPC configuration
    │   │   ├── nat/     # NAT gateway
    │   │   └── vpc-psa/ # Private service access
    │   ├── gke/         # GKE cluster and IAM
    │   │   ├── gke-cluster/    # Standard GKE cluster
    │   │   ├── gke-autopilot/  # Autopilot GKE cluster
    │   │   └── gke-iam/        # IAM bindings
    │   │       ├── docreader/  # DocReader IAM
    │   │       └── faceapi/    # FaceAPI IAM
    │   ├── gsql/        # Cloud SQL PostgreSQL
    │   └── gcs/         # Storage buckets
    │       ├── docreader/      # DocReader bucket
    │       └── faceapi/        # FaceAPI bucket
    ├── apps/            # Application deployments
    │   ├── docreader/   # DocReader Helm deployment
    │   └── faceapi/     # FaceAPI Helm deployment
    └── apps-autopilot/  # Autopilot-specific apps
        ├── docreader/   # DocReader for Autopilot
        └── faceapi/     # FaceAPI for Autopilot
```

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.13
- [Terragrunt](https://terragrunt.gruntwork.io/docs/getting-started/install/) >= 0.8
- [Google Cloud SDK](https://cloud.google.com/sdk/docs/install)
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
- [Helm](https://helm.sh/docs/intro/install/) >= 3.0

## Setup

### 1. Authentication

```bash
# Authenticate with Google Cloud
gcloud auth login
gcloud auth application-default login

# Set your project
gcloud config set project YOUR_PROJECT_ID
```

### 2. License Configuration

Place your Regula license file at `terragrunt/regula.license`

For trial licenses, visit: https://docs.regulaforensics.com/develop/doc-reader-sdk/overview/licensing/#trial-license

---

# Deployment

## Configuration

Edit `terragrunt/project.hcl`:

```hcl
locals {
  # Core project settings
  gcp_project_number = ""  # Your GCP project number
  gcp_project        = ""  # Your GCP project ID
  gcp_region         = "europe-west3"
  gcp_zones          = [
    "europe-west3-a",
    "europe-west3-b",
    "europe-west3-c"
  ]
  project_name       = ""  # Your project name
  project_env        = "dev"
  
  # App configurations
  apps = {
    docreader = {
      name      = "docreader"
      namespace = "docreader"
      deploy    = true
      chart_version = "2.3.0"  # DocReader Helm chart version
    }
    faceapi = {
      name      = "faceapi" 
      namespace = "faceapi"
      deploy    = true
      chart_version = "2.2.0"  # FaceAPI Helm chart version
    }
  }
  
  # Available Helm chart versions: https://github.com/regulaforensics/helm-charts/releases
  
  {
    # Infrastructure settings
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
```

## Configuration Variables

### Core Project Settings
- **gcp_project_number**: GCP project number (numeric ID)
- **gcp_project**: GCP project ID (string identifier)
- **gcp_region**: Primary GCP region for resources
- **gcp_zones**: List of availability zones within the region
- **project_name**: Project name used for resource naming
- **project_env**: Environment identifier (dev, staging, prod)

### Application Configuration
- **apps**: Map of applications to deploy
  - **name**: Application name
  - **namespace**: Kubernetes namespace
  - **chart_version**: Helm chart version
  - **deploy**: Whether to deploy the application

### Infrastructure Settings
- **gke_cluster_name**: GKE cluster name (auto-generated from project_name and project_env)
- **gke_cluster_type**: Cluster type ("standard" or "autopilot")

### Resource Sizing
- **compute.cpu_nodepool**: CPU node pool machine type
- **compute.gpu_nodepool**: GPU node pool machine type
- **compute.db_size**: Cloud SQL instance size

### Additional Settings
- **domain**: Domain prefix for applications
- **license_file_path**: Path to Regula license file

## Deployment Methods

### Full Deployment (One Command)
```bash
cd terragrunt/gcp/gcp-regula-dev
terragrunt apply --all
```

### Step-by-Step Deployment
```bash
cd terragrunt/gcp/gcp-regula-dev

# 1. Enable APIs (optional - can be done manually)
terragrunt apply --terragrunt-working-dir infra/apis

# 2. Deploy VPC infrastructure
terragrunt apply --all --terragrunt-include-dir infra/vpc

# 3. Deploy GKE cluster
terragrunt apply --all --terragrunt-include-dir infra/gke

# 4. Deploy database
terragrunt apply --terragrunt-working-dir infra/gsql

# 5. Deploy storage buckets
terragrunt apply --all --terragrunt-include-dir infra/gcs

# 6. Deploy applications
# For standard cluster:
terragrunt apply --all --terragrunt-include-dir apps
```

### Individual Components
```bash
# Deploy specific component
terragrunt apply --terragrunt-working-dir infra/vpc/vpc
terragrunt apply --terragrunt-working-dir infra/gke/gke-cluster
terragrunt apply --terragrunt-working-dir apps/docreader

# For Autopilot cluster
terragrunt apply --terragrunt-working-dir infra/gke/gke-autopilot
terragrunt apply --terragrunt-working-dir apps-autopilot/docreader
terragrunt apply --terragrunt-working-dir apps-autopilot/faceapi
```

## Accessing the GKE Cluster

After deployment, configure kubectl to access your cluster:

```bash
# Get cluster credentials
gcloud container clusters get-credentials <CLUSTER_NAME> --region <REGION> --project <PROJECT_ID>

# Example:
gcloud container clusters get-credentials regula-dev --region europe-west3 --project your-project-id

# Verify connection
kubectl cluster-info
kubectl get nodes
```

---

# Configuration Reference

## Network Configuration

- **VPC CIDR**: Custom VPC with private subnets
- **Pod Range**: `10.48.0.0/14`
- **Service Range**: `10.52.0.0/20`
- **Private Nodes**: Enabled by default
- **NAT Gateway**: For outbound internet access

## GKE Configuration

- **Cluster Types**: 
  - Standard GKE cluster (default)
  - Autopilot GKE cluster (managed)
- **Node Pools**: 
  - CPU pool: `n4-standard-2` instances (configurable)
  - GPU pool: `g2-standard-4` with NVIDIA L4 GPUs (conditional)
- **Monitoring**: Google Cloud Monitoring and Prometheus
- **Logging**: Comprehensive logging enabled
- **Security**: Private cluster, Workload Identity, Network Policies
- **IAM**: Dedicated service accounts per application

---

# Operations

## Accessing Applications

```bash
# Get cluster credentials
gcloud container clusters get-credentials regula-dev --region europe-west3

# Check deployments
kubectl get pods -n docreader
kubectl get pods -n faceapi
kubectl get services -n docreader
kubectl get services -n faceapi
```

## Monitoring and Logging

- **Google Cloud Monitoring**: Cluster and application metrics
- **Google Cloud Logging**: Centralized logging
- **Prometheus**: Advanced monitoring

## Cleanup

```bash
# Destroy applications first
terragrunt destroy --all --terragrunt-include-dir apps
# Or for autopilot
terragrunt destroy --all --terragrunt-include-dir apps-autopilot

# Destroy infrastructure
terragrunt destroy --all --terragrunt-include-dir infra
```

## Troubleshooting

### Common Issues

1. **Authentication errors**: Run `gcloud auth application-default login`
2. **API not enabled**: Enable required APIs using `infra/apis` component
3. **Insufficient quotas**: Check GCP quotas for compute, GPU, load balancers
4. **License issues**: Ensure license file is present and valid
5. **Network connectivity**: Verify NAT gateway configuration

### Useful Commands

```bash
# Terragrunt
terragrunt plan --all
terragrunt apply --all
terragrunt destroy --all
terragrunt graph-dependencies
terragrunt output --all

# Kubernetes
kubectl cluster-info
kubectl get nodes -o wide
kubectl top nodes
kubectl get pods -n docreader-dev
kubectl get pods -n faceapi-dev
kubectl logs -n docreader-dev deployment/docreader
```

## Support

For issues related to:
- **Infrastructure**: Check Terragrunt logs
- **Applications**: Check Kubernetes pod logs
- **Regula Licenses**: Contact Regula support

## License

This project is licensed under the terms specified in your Regula Forensics license agreement.