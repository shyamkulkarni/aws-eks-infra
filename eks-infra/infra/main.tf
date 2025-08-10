terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.24"
    }
  }

  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "eks-cluster/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = var.region
}

# Optional: Install Argo CD namespace + bootstrap app via Kubernetes provider
provider "kubernetes" {
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.this.token
}

# Kube auth data sources
data "aws_eks_cluster" "this" { 
  name = aws_eks_cluster.this.name 
}

data "aws_eks_cluster_auth" "this" { 
  name = aws_eks_cluster.this.name 
}

resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
}

# Optionally apply Argo CD bootstrap manifest
resource "kubernetes_manifest" "argocd_bootstrap" {
  manifest = yamldecode(file("${path.module}/../cluster-config/argo/argocd-bootstrap.yaml"))
}