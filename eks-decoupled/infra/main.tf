terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.55"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.28"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.13"
    }
  }
}

resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
}

# Optionally apply Argo CD bootstrap manifest
# resource "kubernetes_manifest" "argocd_bootstrap" {
#   manifest = yamldecode(file("${path.module}/../cluster-config/argo/argocd-bootstrap.yaml"))
# }