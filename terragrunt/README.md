# Terragrunt GCP Infrastructure

This directory contains Terragrunt configurations for deploying Regula DocReader and FaceAPI applications on Google Cloud Platform.

## Prerequisites

### Install Required Tools

#### macOS (using Homebrew)
```bash
# Install Homebrew (if not already installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install tools
brew install terraform
brew install terragrunt
brew install --cask google-cloud-sdk

# Initialize gcloud
gcloud init
```

#### Linux (Ubuntu/Debian)
```bash
# Install Terraform
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install terraform

# Install Terragrunt
wget https://github.com/gruntwork-io/terragrunt/releases/download/v0.67.16/terragrunt_linux_amd64
chmod +x terragrunt_linux_amd64
sudo mv terragrunt_linux_amd64 /usr/local/bin/terragrunt

# Install Google Cloud SDK
curl https://sdk.cloud.google.com | bash
exec -l $SHELL
gcloud init
```

### Authentication Setup

```bash
# Authenticate with Google Cloud
gcloud auth login
gcloud auth application-default login

# Set project
gcloud config set project gcp-regula-dev
```

### Enable Required APIs

Enable the following APIs in Google Cloud Console or via CLI:

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

**Required APIs:**
- **Compute Engine API** - For VPC, NAT, and VM instances
- **Kubernetes Engine API** - For GKE cluster management
- **Cloud SQL Admin API** - For PostgreSQL database
- **Cloud Storage API** - For GCS buckets
- **Identity and Access Management API** - For IAM bindings
- **Cloud Resource Manager API** - For project management
- **Service Networking API** - For private service access
- **Cloud Monitoring API** - For cluster monitoring
- **Cloud Logging API** - For centralized logging

## Project Structure

```
terragrunt/
├── project.hcl              # Central configuration
├── root-gcp.hcl            # Remote state configuration
├── provider-gcp.hcl        # GCP provider configuration
├── provider-k8s-gcp.hcl    # Kubernetes provider configuration
├── regula.license          # License file
└── gcp/
    └── gcp-regula-dev/
        ├── infra/          # Infrastructure components
        │   ├── vpc/        # VPC, NAT, PSA
        │   ├── gke/        # GKE cluster and IAM
        │   ├── gsql/       # PostgreSQL database
        │   └── gcs/        # Storage buckets
        └── apps/           # Application deployments
            ├── docreader/  # DocReader application
            └── faceapi/    # FaceAPI application
```

## Configuration Files

### project.hcl

Central configuration file containing all project settings:

- **Core Settings**: GCP project, region, environment
- **App Configurations**: Application names and namespaces
- **Infrastructure Settings**: Cluster name and resource sizing
- **Compute Resources**: Node pool sizes and database specifications

Key variables:
```hcl
locals {
  # Core project settings
  gcp_project        = "gcp-regula-dev"
  gcp_region         = "europe-west3"
  project_name       = "regula"
  project_env        = "dev"
  
  # App configurations
  apps = {
    docreader = { name = "docreader", namespace = "docreader" }
    faceapi   = { name = "faceapi", namespace = "faceapi" }
  }
  
  # Resource sizing
  compute = {
    cpu_nodepool = "n4-standard-2"
    gpu_nodepool = "g2-standard-4"
    db_size      = "db-custom-1-3840"
  }
}
```

## Deployment Instructions

### 1. Deploy Entire Project (One Command)

Deploy all infrastructure and applications with a single command:

```bash
cd terragrunt/gcp/gcp-regula-dev
terragrunt apply --all
```

**Note**: This command will automatically handle dependencies and deploy components in the correct order.

### 2. Deploy Full Infrastructure (Step by Step)

Deploy all components in dependency order:

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

### 3. Deploy Individual Components

#### VPC Infrastructure
```bash
cd terragrunt/gcp/gcp-regula-dev/infra/vpc

# Deploy VPC
terragrunt apply --terragrunt-working-dir vpc

# Deploy NAT Gateway
terragrunt apply --terragrunt-working-dir nat

# Deploy Private Service Access
terragrunt apply --terragrunt-working-dir vpc-psa
```

#### GKE Cluster
```bash
cd terragrunt/gcp/gcp-regula-dev/infra/gke

# Deploy GKE cluster
terragrunt apply --terragrunt-working-dir gke-cluster

# Deploy IAM bindings
terragrunt apply --all --terragrunt-include-dir gke-iam
```

#### Database
```bash
cd terragrunt/gcp/gcp-regula-dev/infra/gsql
terragrunt apply
```

#### Storage Buckets
```bash
cd terragrunt/gcp/gcp-regula-dev/infra/gcs

# Deploy DocReader bucket
terragrunt apply --terragrunt-working-dir docreader

# Deploy FaceAPI bucket
terragrunt apply --terragrunt-working-dir faceapi
```

#### Applications
```bash
cd terragrunt/gcp/gcp-regula-dev/apps

# Deploy DocReader
terragrunt apply --terragrunt-working-dir docreader

# Deploy FaceAPI
terragrunt apply --terragrunt-working-dir faceapi
```

### 3. Useful Commands

```bash
# Plan all changes
terragrunt plan --all

# Apply specific component
terragrunt apply --terragrunt-working-dir path/to/component

# Destroy infrastructure (be careful!)
terragrunt destroy --all

# Show outputs
terragrunt output --terragrunt-working-dir path/to/component

# Validate configuration
terragrunt validate --all
```

## Naming Conventions

The project follows consistent naming patterns:

- **Namespaces**: `{app-name}-{env}` (e.g., `docreader-dev`)
- **Service Accounts**: `{app-name}-{env}` (e.g., `faceapi-dev`)
- **Buckets**: `{project-name}-{app-name}-{env}` (e.g., `regula-docreader-dev`)
- **Domains**: `gcp-{app-name}-{env}.{domain}` (e.g., `gcp-docreader-dev.regula.app`)

## Troubleshooting

### Common Issues

1. **Authentication errors**: Ensure `gcloud auth application-default login` is run
2. **Permission errors**: Verify IAM roles in GCP console
3. **API not enabled errors**: Enable required APIs listed above
4. **State lock errors**: Use `terragrunt force-unlock LOCK_ID`
5. **Dependency errors**: Deploy components in the correct order

### Logs and Debugging

```bash
# Enable debug logging
export TG_LOG=debug
export TF_LOG=DEBUG

# Show dependency graph
terragrunt graph-dependencies
```

## License

Place your `regula.license` file in the root terragrunt directory before deployment.