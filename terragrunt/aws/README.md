# AWS Terragrunt Infrastructure for Regula Forensics

This directory contains the AWS equivalent of the GCP Terragrunt setup for deploying Regula Forensics applications (DocReader and FaceAPI) on AWS infrastructure.

## Architecture Overview

The AWS setup mirrors the GCP structure with the following AWS services:

- **EKS (Elastic Kubernetes Service)** - Replaces GKE
- **RDS PostgreSQL** - Replaces Cloud SQL
- **S3** - Replaces Google Cloud Storage
- **VPC with NAT Gateway** - Replaces GCP VPC
- **Application Load Balancer** - Replaces GCP Load Balancer
- **IAM Roles for Service Accounts (IRSA)** - Replaces GCP Workload Identity

## Directory Structure

```
terragrunt/aws/
├── aws-regula-dev/
│   ├── apps/
│   │   ├── docreader/
│   │   │   ├── main.tf
│   │   │   └── terragrunt.hcl
│   │   └── faceapi/
│   │       ├── main.tf
│   │       └── terragrunt.hcl
│   └── infra/
│       ├── vpc/
│       │   ├── vpc/
│       │   │   └── terragrunt.hcl
│       │   └── vpc-endpoints/
│       │       └── terragrunt.hcl
│       ├── eks/
│       │   └── eks-cluster/
│       │       └── terragrunt.hcl
│       ├── rds/
│       │   └── terragrunt.hcl
│       └── s3/
│           ├── docreader/
│           │   └── terragrunt.hcl
│           └── faceapi/
│               └── terragrunt.hcl
├── project-aws.hcl
├── provider-aws.hcl
├── provider-k8s-aws.hcl
├── root-aws.hcl
└── README.md
```

## Prerequisites

1. **AWS CLI** configured with appropriate credentials
2. **Terraform** >= 1.0
3. **Terragrunt** >= 0.45
4. **kubectl** for Kubernetes management
5. **helm** for application deployment
6. **PostgreSQL client** (psql) for database operations

## Configuration

### 1. Update project-aws.hcl

Edit `terragrunt/project-aws.hcl` and fill in the required values:

```hcl
locals {
  aws_account_id = "123456789012"  # Your AWS Account ID
  project_name   = "regula-demo"   # Your project name
  domain         = "example.com"   # Your domain
}
```

### 2. Create S3 Backend Bucket

Before running Terragrunt, create the S3 bucket for Terraform state:

```bash
aws s3 mb s3://terraform-regula-demo-123456789012
aws dynamodb create-table \
  --table-name terraform-regula-demo-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5
```

### 3. Copy License File

Copy your `regula.license` file to the `terragrunt/` directory.

## Deployment Order

Deploy the infrastructure in the following order:

### 1. VPC Infrastructure
```bash
cd terragrunt/aws/aws-regula-dev/infra/vpc/vpc
terragrunt apply

cd ../vpc-endpoints
terragrunt apply
```

### 2. EKS Cluster
```bash
cd ../../eks/eks-cluster
terragrunt apply
```

### 3. RDS Database
```bash
cd ../../rds
terragrunt apply
```

### 4. S3 Buckets
```bash
cd ../s3/docreader
terragrunt apply

cd ../faceapi
terragrunt apply
```

### 5. Applications
```bash
# Install AWS Load Balancer Controller first
kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller//crds?ref=master"

# Deploy applications
cd ../../../apps/docreader
terragrunt apply

cd ../faceapi
terragrunt apply
```

## Key Differences from GCP Setup

### Authentication
- **GCP**: Uses Workload Identity
- **AWS**: Uses IAM Roles for Service Accounts (IRSA)

### Load Balancing
- **GCP**: Uses GCE Ingress with Global Load Balancer
- **AWS**: Uses AWS Load Balancer Controller with Application Load Balancer

### Storage
- **GCP**: Google Cloud Storage with uniform bucket-level access
- **AWS**: S3 with IAM policies for bucket access

### Database
- **GCP**: Cloud SQL with private IP and VPC peering
- **AWS**: RDS with VPC security groups and Secrets Manager for credentials

### Networking
- **GCP**: VPC with Private Service Access
- **AWS**: VPC with NAT Gateway and VPC Endpoints

## Monitoring and Observability

The setup includes:
- ServiceMonitor resources for Prometheus scraping
- Pod Disruption Budgets for high availability
- Topology Spread Constraints for zone distribution
- Horizontal Pod Autoscaling

## Security Features

- Private subnets for EKS worker nodes
- Security groups with minimal required access
- S3 bucket encryption and versioning
- RDS encryption at rest
- VPC endpoints for private AWS service access
- IAM roles with least privilege access

## Cleanup

To destroy the infrastructure:

```bash
# Destroy applications first
cd terragrunt/aws/aws-regula-dev/apps/docreader
terragrunt destroy

cd ../faceapi
terragrunt destroy

# Then destroy infrastructure
cd ../../infra/s3/docreader
terragrunt destroy

cd ../faceapi
terragrunt destroy

cd ../../rds
terragrunt destroy

cd ../eks/eks-cluster
terragrunt destroy

cd ../../vpc/vpc-endpoints
terragrunt destroy

cd ../vpc
terragrunt destroy
```

## Troubleshooting

### Common Issues

1. **EKS Cluster Access**: Ensure your AWS credentials have the necessary permissions and the cluster creator is added to the aws-auth ConfigMap.

2. **Load Balancer Controller**: Make sure the AWS Load Balancer Controller is installed and has the correct IAM permissions.

3. **Database Connectivity**: Verify security group rules allow traffic from EKS worker nodes to RDS on port 5432.

4. **S3 Access**: Check that IRSA is properly configured and the service account has the correct annotations.

### Useful Commands

```bash
# Update kubeconfig
aws eks update-kubeconfig --region us-west-2 --name regula-demo-dev

# Check cluster status
kubectl get nodes

# View application logs
kubectl logs -n docreader-dev deployment/docreader

# Check ingress status
kubectl get ingress -A
```