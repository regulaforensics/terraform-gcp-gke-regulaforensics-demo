include "root" {
  path = find_in_parent_folders("root-aws.hcl")
}

include "provider" {
  path = find_in_parent_folders("provider-aws.hcl")
}

locals {
  project = read_terragrunt_config(find_in_parent_folders("project-aws.hcl")).locals
}

terraform {
  source = "tfr:///terraform-aws-modules/eks/aws?version=21.11.0"
}

dependency "vpc" {
  config_path = "../../vpc/vpc"
  mock_outputs = {
    vpc_id = "vpc-12345678"
    private_subnets = ["subnet-12345678", "subnet-87654321"]
    public_subnets = ["subnet-12345679", "subnet-87654322"]
  }
}

inputs = {
  name            = local.project.eks_cluster_name
  cluster_version = "1.29"

  vpc_id                         = dependency.vpc.outputs.vpc_id
  subnet_ids                     = dependency.vpc.outputs.private_subnets
  control_plane_subnet_ids       = dependency.vpc.outputs.private_subnets

  # Cluster access entry
  enable_cluster_creator_admin_permissions = true

  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    aws-ebs-csi-driver = {
      most_recent = true
    }
    aws-efs-csi-driver = {
      most_recent = true
    }
  }

  # EKS Managed Node Groups
  eks_managed_node_groups = {
    cpu_nodegroup = {
      name = "cpu-nodepool"
      
      instance_types = [local.project.compute.cpu_nodegroup]
      
      min_size     = 1
      max_size     = 10
      desired_size = 2

      kubernetes_version = "1.29"

      labels = {
        nodepool = "cpu-nodepool"
      }

      taints = {}
    }

    gpu_nodegroup = {
      name = "gpu-nodepool"
      
      instance_types = [local.project.compute.gpu_nodegroup]
      
      min_size     = 0
      max_size     = 5
      desired_size = 0

      kubernetes_version = "1.29"

      labels = {
        nodepool = "gpu-nodepool"
      }

      taints = {
        gpu = {
          key    = "nvidia.com/gpu"
          value  = "true"
          effect = "NO_SCHEDULE"
        }
      }
    }
  }

  tags = {
    Name = local.project.eks_cluster_name
  }
}