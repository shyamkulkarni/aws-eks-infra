# AWS EKS Infrastructure

This repository contains Terraform configurations for deploying a production-ready EKS cluster on AWS with comprehensive monitoring, logging, and GitOps capabilities.

## Infrastructure Architecture


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

2. **Configure variables**
   ```bash
   cd infra
   # Edit terraform.tfvars with your values
   ```

3. **Deploy infrastructure**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

4. **Configure kubectl**
   ```bash
   aws eks update-kubeconfig --region us-east-1 --name your-cluster-name
   ```

## Directory Structure

```
infra/
├── main.tf              # Main Terraform configuration
├── vpc.tf               # VPC and networking resources
├── eks.tf               # EKS cluster configuration
├── iam-irsa.tf          # IAM roles for service accounts
├── variables.tf         # Variable definitions
├── terraform.tfvars     # Variable values
├── versions.tf          # Terraform and provider versions
├── providers.tf         # AWS provider configuration
├── outputs.tf           # Output values
└── locals.tf            # Local variable definitions
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

This project is licensed under the MIT License.
