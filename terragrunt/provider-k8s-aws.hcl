locals {
  project = read_terragrunt_config(find_in_parent_folders("project-aws.hcl")).locals
}

generate "provider-kubernetes" {
  path      = "_provider_kubernetes.tf"
  if_exists = "overwrite"
  contents  = <<EOF

data "aws_eks_cluster" "cluster" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name = var.cluster_name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

provider "helm" {
  kubernetes = {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

EOF
}