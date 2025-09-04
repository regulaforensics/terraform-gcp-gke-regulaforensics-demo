# GCP GKE Regula Forensics Demo

This repository provides two deployment approaches for Regula Forensics applications (DocReader and FaceAPI) on Google Kubernetes Engine (GKE): a **Terraform module** for simple deployments and a **Terragrunt configuration** for production-grade infrastructure management.

## Architecture Overview

The infrastructure deploys:
- **GKE Cluster**: Private Kubernetes cluster with CPU and GPU node pools
- **VPC Network**: Custom VPC with private subnets and NAT gateway
- **Cloud SQL**: PostgreSQL database for application data
- **Cloud Storage**: GCS buckets for application storage
- **Helm Applications**: DocReader and FaceAPI services

## Project Structure

```
├── terraform/                 # Terraform module (simple deployment)
│   ├── module/                # Core infrastructure module
│   │   ├── 0-project.tf      # Project configuration
│   │   ├── 1-vpc.tf          # VPC and networking
│   │   ├── 2-gke_cluster.tf  # GKE cluster
│   │   ├── 3-router_nat.tf   # NAT gateway
│   │   ├── 4-helm.tf         # Helm deployments
│   │   └── 5-gke_auth.tf     # GKE authentication
│   └── main.tf               # Root module
└── terragrunt/               # Terragrunt configuration (production-grade)
    ├── project.hcl           # Central configuration
    ├── root-gcp.hcl         # Remote state configuration
    ├── provider-*.hcl       # Provider configurations
    ├── regula.license       # License file
    └── gcp/gcp-regula-dev/
        ├── infra/           # Infrastructure components
        │   ├── vpc/         # VPC, NAT, PSA
        │   ├── gke/         # GKE cluster and IAM
        │   ├── gsql/        # Cloud SQL
        │   └── gcs/         # Storage buckets
        └── apps/            # Application deployments
            ├── docreader/
            └── faceapi/
```

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) >= 1.0
- [Terragrunt](https://terragrunt.gruntwork.io/docs/getting-started/install/) >= 0.45 (for Terragrunt approach)
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

### 2. Enable Required APIs

```bash
# Enable required Google Cloud APIs
gcloud services enable compute.googleapis.com
gcloud services enable container.googleapis.com
gcloud services enable sqladmin.googleapis.com
gcloud services enable storage.googleapis.com
gcloud services enable iam.googleapis.com
gcloud services enable cloudresourcemanager.googleapis.com
gcloud services enable servicenetworking.googleapis.com
gcloud services enable monitoring.googleapis.com
gcloud services enable logging.googleapis.com
```

### 3. License Configuration

Place your Regula license file:
- **Terraform**: In your project directory as `regula.license`
- **Terragrunt**: At `terragrunt/regula.license`

---

# Deployment Options

## Option 1: Terraform Module (Simple Deployment)

**Best for**: Quick deployments, testing, simple environments

### Setup

1. **Create credentials file**:
   ```bash
   # Create and download service account key
   export GOOGLE_APPLICATION_CREDENTIALS="/path/to/credentials.json"
   ```

2. **Create main.tf**:
   ```hcl
   module "gke_cluster" {
     source            = "./terraform"
     project_id        = "your-project-id"
     region            = "europe-west3"
     zones             = ["europe-west3-a", "europe-west3-b"]
     name              = "regula-dev"
     enable_docreader  = true
     enable_faceapi    = true
     docreader_license = filebase64("regula.license")
     face_api_license  = filebase64("regula.license")
   }
   
   # Generate kubeconfig
   resource "local_file" "kubeconfig" {
     content  = module.gke_cluster.config
     filename = "kubeconfig"
   }
   ```

3. **Deploy**:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

### Custom Helm Values (Optional)

```hcl
# Custom DocReader values
data "template_file" "docreader_values" {
  template = file("values/docreader/values.yml")
}

# Custom FaceAPI values
data "template_file" "faceapi_values" {
  template = file("values/faceapi/values.yml")
}

module "gke_cluster" {
  # ... other variables
  docreader_values = data.template_file.docreader_values.rendered
  faceapi_values   = data.template_file.faceapi_values.rendered
}
```

---

## Option 2: Terragrunt (Production-Grade)

**Best for**: Production environments, complex deployments, team collaboration

### Configuration

Edit `terragrunt/project.hcl`:

```hcl
locals {
  # Core project settings
  gcp_project        = "your-project-id"
  gcp_region         = "europe-west3"
  gcp_zones          = ["europe-west3-a", "europe-west3-b", "europe-west3-c"]
  project_name       = "regula"
  project_env        = "dev"
  
  # App configurations
  apps = {
    docreader = { name = "docreader", namespace = "docreader", deploy = true }
    faceapi   = { name = "faceapi", namespace = "faceapi", deploy = true }
  }
  
  # Resource sizing
  compute = {
    cpu_nodepool = "n4-standard-2"
    gpu_nodepool = "g2-standard-4"
    db_size      = "db-custom-1-3840"
  }
}
```

### Deployment Methods

#### Full Deployment (One Command)
```bash
cd terragrunt/gcp/gcp-regula-dev
terragrunt apply --all
```

#### Step-by-Step Deployment
```bash
cd terragrunt/gcp/gcp-regula-dev

# 1. Deploy VPC infrastructure
terragrunt apply --all --terragrunt-include-dir infra/vpc

# 2. Deploy GKE cluster
terragrunt apply --all --terragrunt-include-dir infra/gke

# 3. Deploy database
terragrunt apply --terragrunt-working-dir infra/gsql

# 4. Deploy storage buckets
terragrunt apply --all --terragrunt-include-dir infra/gcs

# 5. Deploy applications
terragrunt apply --all --terragrunt-include-dir apps
```

#### Individual Components
```bash
# Deploy specific component
terragrunt apply --terragrunt-working-dir infra/vpc/vpc
terragrunt apply --terragrunt-working-dir infra/gke/gke-cluster
terragrunt apply --terragrunt-working-dir apps/docreader
```

---

# Configuration Reference

## Key Variables (Terraform)

| Variable | Description | Default |
|----------|-------------|---------|
| `project_id` | GCP Project ID | - |
| `region` | GCP Region | - |
| `zones` | Deployment zones | - |
| `name` | Cluster name | - |
| `machine_type` | Node machine type | `e2-standard-4` |
| `node_count` | Number of nodes | `1` |
| `enable_docreader` | Deploy DocReader | `false` |
| `enable_faceapi` | Deploy FaceAPI | `false` |
| `docreader_license` | DocReader license (base64) | - |
| `face_api_license` | FaceAPI license (base64) | - |

## Network Configuration

- **VPC CIDR**: Custom VPC with private subnets
- **Pod Range**: `10.48.0.0/14`
- **Service Range**: `10.52.0.0/20`
- **Private Nodes**: Enabled by default
- **NAT Gateway**: For outbound internet access

## GKE Configuration

- **Node Pools**: 
  - CPU pool: `n4-standard-2` instances (1-10 nodes)
  - GPU pool: `g2-standard-4` with NVIDIA L4 GPUs (1-3 nodes, conditional)
- **Monitoring**: Google Cloud Monitoring and Prometheus
- **Logging**: Comprehensive logging enabled
- **Security**: Private cluster, Workload Identity, Network Policies

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
- **Prometheus**: Advanced monitoring (Terragrunt only)

## Cleanup

### Terraform
```bash
terraform destroy
```

### Terragrunt
```bash
# Destroy applications first
terragrunt destroy --all --terragrunt-include-dir apps

# Destroy infrastructure
terragrunt destroy --all --terragrunt-include-dir infra
```

## Troubleshooting

### Common Issues

1. **Authentication errors**: Run `gcloud auth application-default login`
2. **API not enabled**: Enable required APIs listed above
3. **Insufficient quotas**: Check GCP quotas for compute, GPU, load balancers
4. **License issues**: Ensure license file is present and valid
5. **Network connectivity**: Verify NAT gateway configuration

### Useful Commands

```bash
# Terraform
terraform plan
terraform apply
terraform destroy

# Terragrunt
terragrunt plan --all
terragrunt apply --all
terragrunt destroy --all
terragrunt graph-dependencies

# Kubernetes
kubectl cluster-info
kubectl get nodes -o wide
kubectl top nodes
kubectl logs -n docreader deployment/docreader
```

## Support

For issues related to:
- **Infrastructure**: Check Terraform/Terragrunt logs
- **Applications**: Check Kubernetes pod logs
- **Regula Licenses**: Contact Regula support

## License

This project is licensed under the terms specified in your Regula Forensics license agreement.