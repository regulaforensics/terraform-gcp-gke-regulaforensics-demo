# AWS Terragrunt Usage Guide

## Important: Running Terragrunt Commands

**Terragrunt must be run from specific component directories, NOT from the root aws directory.**

## Correct Usage

### Set AWS Profile
```bash
export AWS_PROFILE=Sandbox-AdminAccess
```

### Navigate to Specific Component
```bash
# For VPC
cd terragrunt/aws/aws-regula-dev/infra/vpc/vpc

# For EKS
cd terragrunt/aws/aws-regula-dev/infra/eks/eks-cluster

# For RDS
cd terragrunt/aws/aws-regula-dev/infra/rds

# For S3 buckets
cd terragrunt/aws/aws-regula-dev/infra/s3/docreader
cd terragrunt/aws/aws-regula-dev/infra/s3/faceapi

# For applications
cd terragrunt/aws/aws-regula-dev/apps/docreader
cd terragrunt/aws/aws-regula-dev/apps/faceapi
```

### Run Terragrunt Commands
```bash
# Plan (see what will be created)
terragrunt plan

# Apply (create resources)
terragrunt apply

# Destroy (delete resources)
terragrunt destroy
```

## Deployment Order

Deploy infrastructure in this order:

1. **VPC Infrastructure**
   ```bash
   cd terragrunt/aws/aws-regula-dev/infra/vpc/vpc
   terragrunt apply
   
   cd ../vpc-endpoints
   terragrunt apply
   ```

2. **EKS Cluster**
   ```bash
   cd ../../eks/eks-cluster
   terragrunt apply
   ```

3. **RDS Database**
   ```bash
   cd ../../rds
   terragrunt apply
   ```

4. **S3 Buckets**
   ```bash
   cd ../s3/docreader
   terragrunt apply
   
   cd ../faceapi
   terragrunt apply
   ```

5. **Applications** (after infrastructure is ready)
   ```bash
   cd ../../../apps/docreader
   terragrunt apply
   
   cd ../faceapi
   terragrunt apply
   ```

## Using the Deployment Script

Alternatively, use the automated deployment script:

```bash
cd terragrunt/aws

# Plan all infrastructure
./deploy.sh plan

# Deploy all infrastructure
./deploy.sh apply

# Plan specific component
./deploy.sh plan infra/vpc/vpc

# Deploy specific component
./deploy.sh apply infra/eks/eks-cluster
```

## Common Errors

### ❌ Wrong: Running from root aws directory
```bash
cd terragrunt/aws
terragrunt plan  # This will fail!
```

### ✅ Correct: Running from component directory
```bash
cd terragrunt/aws/aws-regula-dev/infra/vpc/vpc
terragrunt plan  # This works!
```

## Current Status

✅ S3 backend bucket created: `terraform-regula-demo-894602450013`  
✅ DynamoDB lock table created: `terraform-regula-demo-locks`  
✅ AWS credentials configured for profile: `Sandbox-AdminAccess`  
✅ VPC component tested and working  

You're ready to deploy!