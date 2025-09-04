# GCP GKE Regula Forensics Demo

This repository contains Terraform and Terragrunt configurations for deploying Regula Forensics applications (DocReader and FaceAPI) on Google Kubernetes Engine (GKE) in Google Cloud Platform.

## Architecture Overview

The infrastructure deploys:
- **GKE Cluster**: Private Kubernetes cluster with CPU and GPU node pools
- **VPC Network**: Custom VPC with private subnets and NAT gateway
- **Cloud SQL**: PostgreSQL database for application data
- **Cloud Storage**: GCS buckets for application storage
- **Helm Applications**: DocReader and FaceAPI services

## Project Structure

```
├── terraform/                 # Terraform modules
│   ├── module/                # Core infrastructure module
│   │   ├── 0-project.tf      # Project configuration
│   │   ├── 1-vpc.tf          # VPC and networking
│   │   ├── 2-gke_cluster.tf  # GKE cluster
│   │   ├── 3-router_nat.tf   # NAT gateway
│   │   ├── 4-helm.tf         # Helm deployments
│   │   └── 5-gke_auth.tf     # GKE authentication
│   └── main.tf               # Root module
└── terragrunt/               # Terragrunt configurations
    ├── gcp/
    │   └── gcp-regula-dev/
    │       ├── infra/        # Infrastructure components
    │       │   ├── apis/     # GCP APIs
    │       │   ├── gke/      # GKE configurations
    │       │   ├── vpc/      # VPC configurations
    │       │   └── gsql/     # Cloud SQL
    │       └── apps/         # Application deployments
    │           ├── docreader/
    │           └── faceapi/
    └── *.hcl                 # Terragrunt configuration files
```

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) >= 1.0
- [Terragrunt](https://terragrunt.gruntwork.io/docs/getting-started/install/) >= 0.45
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

### 2. Configure Project Settings

Edit `terragrunt/project.hcl`:

```hcl
locals {
  gcp_project_number = YOUR_PROJECT_NUMBER
  gcp_project        = "YOUR_PROJECT_ID"
  gcp_region         = "europe-west3"
  gcp_zones          = [
    "europe-west3-a",
    "europe-west3-b",
    "europe-west3-c"
  ]
  project_name       = "regula"
  project_env        = "dev"
}
```

### 3. License Configuration

Place your Regula license file at `terragrunt/regula.license`

## Deployment Options

### Option 1: Using Terragrunt (Recommended)

Deploy infrastructure components:

```bash
cd terragrunt/gcp/gcp-regula-dev

# Deploy VPC
terragrunt run-all apply --terragrunt-include-dir infra/vpc

# Deploy GKE cluster
terragrunt run-all apply --terragrunt-include-dir infra/gke

# Deploy applications
terragrunt run-all apply --terragrunt-include-dir apps
```

### Option 2: Using Terraform

```bash
cd terraform

# Initialize
terraform init

# Plan deployment
terraform plan -var="project_id=YOUR_PROJECT_ID" \
               -var="region=europe-west3" \
               -var="name=regula-dev" \
               -var="zones=[\"europe-west3-a\",\"europe-west3-b\"]"

# Apply
terraform apply
```

## Configuration

### Key Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `project_id` | GCP Project ID | - |
| `region` | GCP Region | `europe-west3` |
| `name` | Cluster name | `regula-dev` |
| `machine_type` | Node machine type | `e2-standard-4` |
| `node_count` | Number of nodes | `2` |
| `enable_docreader` | Deploy DocReader | `false` |
| `enable_faceapi` | Deploy FaceAPI | `false` |

### Network Configuration

- **VPC CIDR**: Custom VPC with private subnets
- **Pod Range**: `10.48.0.0/14`
- **Service Range**: `10.52.0.0/20`
- **Private Nodes**: Enabled by default
- **NAT Gateway**: For outbound internet access

### GKE Configuration

- **Node Pools**: 
  - CPU pool: `n4-standard-2` instances
  - GPU pool: `g2-standard-4` with NVIDIA L4 GPUs (conditional)
- **Autoscaling**: Enabled (1-10 nodes for CPU, 1-3 for GPU)
- **Monitoring**: Google Cloud Monitoring enabled
- **Logging**: Comprehensive logging enabled

## Application Deployment

### DocReader

```bash
# Enable DocReader deployment
terragrunt apply --terragrunt-include-dir apps/docreader
```

### FaceAPI

```bash
# Enable FaceAPI deployment (requires GPU nodes)
terragrunt apply --terragrunt-include-dir apps/faceapi
```

## Accessing Applications

### Get Cluster Credentials

```bash
gcloud container clusters get-credentials regula-dev --region europe-west3
```

### Check Deployments

```bash
kubectl get pods -n docreader
kubectl get pods -n faceapi
kubectl get services -n docreader
kubectl get services -n faceapi
```

## Monitoring and Logging

- **Google Cloud Monitoring**: Enabled for cluster metrics
- **Google Cloud Logging**: Comprehensive logging for all components
- **Prometheus**: Managed Prometheus for advanced monitoring

## Security Features

- **Private GKE Cluster**: Nodes have no external IPs
- **Network Policies**: Kubernetes network policies enabled
- **Workload Identity**: Secure pod-to-GCP service authentication
- **Private Google Access**: Enabled for accessing Google APIs

## Cleanup

### Terragrunt

```bash
# Destroy applications first
terragrunt run-all destroy --terragrunt-include-dir apps

# Destroy infrastructure
terragrunt run-all destroy --terragrunt-include-dir infra
```

### Terraform

```bash
cd terraform
terraform destroy
```

## Troubleshooting

### Common Issues

1. **Insufficient Quotas**: Ensure your GCP project has sufficient quotas for:
   - Compute Engine instances
   - GPUs (if using FaceAPI)
   - Load balancers

2. **Network Connectivity**: Verify NAT gateway is properly configured for private nodes

3. **License Issues**: Ensure `regula.license` file is present and valid

### Useful Commands

```bash
# Check cluster status
kubectl cluster-info

# View node status
kubectl get nodes -o wide

# Check resource usage
kubectl top nodes
kubectl top pods --all-namespaces

# View logs
kubectl logs -n docreader deployment/docreader
kubectl logs -n faceapi deployment/faceapi
```

## Support

For issues related to:
- **Infrastructure**: Check Terraform/Terragrunt logs
- **Applications**: Check Kubernetes pod logs
- **Regula Licenses**: Contact Regula support

## License

This project is licensed under the terms specified in your Regula Forensics license agreement.