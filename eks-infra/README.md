# AWS EKS Infrastructure

This repository contains Terraform configurations for deploying a production-ready EKS cluster on AWS with comprehensive monitoring, logging, and GitOps capabilities.

## Infrastructure Architecture

```mermaid
flowchart LR
  subgraph AWS[Amazon Web Services - us-east-1]
    subgraph VPC[VPC 10.0.0.0/16]
      direction LR
      subgraph Pub[Public Subnets (AZ-a/b/c)]
        IGW[Internet Gateway]
        ALB[(ALB)]
      end
      subgraph Pri[Private Subnets (AZ-a/b/c)]
        EKS[EKS Control Plane (HA)]
        N1[Managed Node Group - On-Demand]
        N2[Managed Node Group - Spot (optional)]
        NS[Core Add-ons: Argo CD, ALB Controller, ExternalDNS, cert-manager, Metrics Server, Prometheus, Grafana, Fluent Bit]
        APP[Your Apps (Deploy via Argo CD)]
      end
      NAT[NAT Gateways]
      R53[Route 53 Hosted Zone]
    end
    CW[CloudWatch Logs & Metrics]
    SM[Secrets Manager]
    ACM[ACM Certificates]
  end
```

## Features

- **Multi-AZ EKS Cluster**: High availability across 3 availability zones
- **GitOps with Argo CD**: Automated application deployment and management
- **Load Balancing**: Application Load Balancer with ALB Controller
- **DNS Management**: ExternalDNS integration with Route 53
- **SSL/TLS**: Automated certificate management with cert-manager
- **Monitoring**: Prometheus, Grafana, and CloudWatch integration
- **Logging**: Centralized logging with Fluent Bit
- **Security**: IAM roles for service accounts (IRSA) and private subnets

## Prerequisites

- AWS CLI configured with appropriate permissions
- Terraform >= 1.0
- kubectl
- AWS account with EKS service enabled

## Quick Start

1. **Clone the repository**
   ```bash
   git clone https://github.com/shyamkulkarni/aws-eks-infra.git
   cd aws-eks-infra
   ```

2. **Configure variables (optional)**
   ```bash
   cd infra
   # Edit terraform.tfvars if you want to customize defaults
   cd ..
   ```

3. **Deploy infrastructure and Argo CD**
   ```bash
   # Use the bootstrap script for complete deployment
   ./bootstrap.sh
   
   # Or deploy manually:
   cd infra
   terraform init
   terraform plan
   terraform apply
   cd ..
   
   # Update placeholder values
   ./update-placeholders.sh
   
   # Deploy Argo CD
   kubectl apply -f cluster-config/argo/argo-namespace.yaml
   kubectl apply -f cluster-config/argo/values.yaml
   kubectl apply -f cluster-config/apps/app-of-apps.yaml
   ```

4. **Access Argo CD**
   ```bash
   # Get admin password
   kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
   
   # Port forward to access UI locally
   kubectl port-forward svc/argocd-server -n argocd 8080:443
   # Then visit: https://localhost:8080 (username: admin)
   ```

## Directory Structure

```
infra/                           # Terraform infrastructure code
├── main.tf                      # Main Terraform configuration
├── vpc.tf                       # VPC, subnets, security groups
├── eks.tf                       # EKS cluster and node groups
├── iam-irsa.tf                  # IAM roles for service accounts
├── variables.tf                 # Variable definitions with validation
├── terraform.tfvars             # Variable values
├── versions.tf                  # Terraform and provider versions
├── providers.tf                 # AWS provider configuration
├── outputs.tf                   # Output values
└── locals.tf                    # Local variable definitions

cluster-config/                   # Argo CD application configurations
├── apps/                        # Application definitions
│   ├── app-of-apps.yaml        # Root application for add-ons
│   └── addons/                 # Kubernetes add-ons
│       ├── aws-load-balancer-controller/
│       ├── cert-manager/
│       ├── cluster-autoscaler/
│       ├── external-dns/
│       ├── fluent-bit/
│       ├── kube-prometheus-stack/
│       └── metrics-server/
├── argo/                        # Argo CD configuration
└── platform/                    # Platform namespaces

apps/                            # Application manifests
├── backend.yaml                 # Backend application
├── frontend.yaml                # Frontend application
├── ingress.yaml                 # Ingress configuration
└── namespaces-and-networkpolicy.yaml

bootstrap.sh                     # Complete deployment script
update-placeholders.sh           # Post-deployment value updater
```

## Production Checklist

Before deploying to production, ensure you have:

- [ ] **Security Groups**: Properly configured and restrictive
- [ ] **IAM Policies**: Least privilege access configured
- [ ] **Network Policies**: Pod-to-pod communication restricted
- [ ] **Secrets Management**: No hardcoded credentials
- [ ] **Monitoring**: Prometheus and Grafana configured
- [ ] **Logging**: Centralized logging with retention policies
- [ ] **Backup Strategy**: EBS snapshots and cluster backups
- [ ] **Disaster Recovery**: Multi-region or backup cluster plan
- [ ] **Cost Optimization**: Spot instances and savings plans
- [ ] **Compliance**: Meet your organization's security requirements

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

This project is licensed under the MIT License.
