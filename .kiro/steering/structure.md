# Project Structure

## Root Directory Layout

```
terragrunt/                    # Main Terragrunt configuration directory
├── project.hcl               # GCP project configuration and variables
├── project-aws.hcl           # AWS project configuration and variables
├── root-gcp.hcl             # GCP remote state configuration
├── root-aws.hcl             # AWS remote state configuration
├── provider-*.hcl           # Provider configurations (AWS, GCP, K8s)
├── regula.license           # Required Regula Forensics license file
├── aws/                     # AWS-specific infrastructure
├── gcp/                     # GCP-specific infrastructure
└── README files             # Documentation and usage guides
```

## Cloud-Specific Structure

### GCP Structure (`terragrunt/gcp/gcp-regula-dev/`)
```
infra/                        # Infrastructure components
├── apis/                    # GCP API enablement
├── vpc/                     # Network infrastructure
│   ├── vpc/                # VPC configuration
│   ├── nat/                # NAT gateway
│   └── vpc-psa/            # Private Service Access
├── gke/                     # Kubernetes infrastructure
│   ├── gke-cluster/        # Standard GKE cluster
│   ├── gke-autopilot/      # Autopilot GKE cluster
│   └── gke-iam/            # IAM bindings per app
│       ├── docreader/
│       └── faceapi/
├── gsql/                    # Cloud SQL PostgreSQL
└── gcs/                     # Cloud Storage buckets
    ├── docreader/
    └── faceapi/

apps/                         # Application deployments (standard GKE)
├── docreader/
└── faceapi/

apps-autopilot/              # Application deployments (autopilot GKE)
├── docreader/
└── faceapi/
```

### AWS Structure (`terragrunt/aws/aws-regula-dev/`)
```
infra/                        # Infrastructure components
├── vpc/                     # Network infrastructure
│   ├── vpc/                # VPC configuration
│   └── vpc-endpoints/      # VPC endpoints
├── eks/                     # Kubernetes infrastructure
│   ├── eks-cluster/        # EKS cluster
│   ├── eks-iam/            # IAM roles
│   └── eks-nodegroups/     # Node groups
├── rds/                     # RDS PostgreSQL
└── s3/                      # S3 storage buckets
    ├── docreader/
    └── faceapi/

apps/                         # Application deployments
├── docreader/
└── faceapi/
```

## File Naming Conventions

### Terragrunt Files
- `terragrunt.hcl` - Main Terragrunt configuration in each module
- `main.tf` - Terraform configuration for application modules
- `project.hcl` / `project-aws.hcl` - Central project configuration
- `provider-*.hcl` - Provider-specific configurations
- `root-*.hcl` - Remote state and backend configuration

### Configuration Patterns
- **Environment suffix**: `-dev`, `-staging`, `-prod`
- **Cloud prefix**: `gcp-` or `aws-` for cloud-specific resources
- **Application naming**: `docreader`, `faceapi` (lowercase, no hyphens)
- **Resource naming**: `${project_name}-${environment}` pattern

## Module Organization

### Infrastructure Modules
- **Ordered deployment**: VPC → Kubernetes → Database → Storage → Apps
- **Dependency management**: Uses Terragrunt `dependency` blocks
- **Mock outputs**: Provided for planning without dependencies

### Application Modules
- **Per-app structure**: Separate directories for docreader and faceapi
- **Shared configuration**: Common settings in project.hcl files
- **Environment-specific**: Namespace and resource naming includes environment

## Configuration Hierarchy

1. **Root configuration** (`root-*.hcl`) - Backend and state management
2. **Provider configuration** (`provider-*.hcl`) - Cloud provider settings
3. **Project configuration** (`project*.hcl`) - Variables and app settings
4. **Module configuration** (`terragrunt.hcl`) - Module-specific settings

## Key Directories to Understand

- **`terragrunt/`** - All infrastructure code lives here
- **`infra/`** - Infrastructure components (networking, compute, storage)
- **`apps/`** - Application deployments (Helm charts)
- **`.terragrunt-cache/`** - Auto-generated, should be in .gitignore
- **`.terraform/`** - Auto-generated Terraform state, should be in .gitignore

## Deployment Dependencies

### Infrastructure Order
1. APIs/Project setup
2. VPC and networking
3. Kubernetes cluster
4. Database services
5. Storage buckets
6. IAM and security
7. Applications

### Cross-Module Dependencies
- Apps depend on infrastructure outputs (cluster endpoint, database connection)
- Storage modules depend on IAM setup
- Kubernetes apps depend on cluster and storage being ready

## Environment Management

- **Single environment per directory**: Each `*-regula-dev/` represents one environment
- **Environment variables**: Set in project configuration files
- **Resource isolation**: Complete separation between environments
- **Naming consistency**: All resources include environment suffix