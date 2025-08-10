#!/bin/bash
set -e

echo "🚀 Starting EKS Infrastructure Bootstrap..."

# Check prerequisites
command -v terraform >/dev/null 2>&1 || { echo "❌ Terraform is required but not installed. Aborting." >&2; exit 1; }
command -v aws >/dev/null 2>&1 || { echo "❌ AWS CLI is required but not installed. Aborting." >&2; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo "❌ kubectl is required but not installed. Aborting." >&2; exit 1; }

# Check AWS credentials
aws sts get-caller-identity >/dev/null 2>&1 || { echo "❌ AWS credentials not configured. Run 'aws configure' first." >&2; exit 1; }

echo "✅ Prerequisites check passed"

# Navigate to infra directory
cd infra

# Initialize Terraform
echo "🔧 Initializing Terraform..."
terraform init

# Plan deployment
echo "📋 Planning Terraform deployment..."
terraform plan

# Confirm deployment
read -p "🤔 Do you want to proceed with the deployment? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Deployment cancelled"
    exit 1
fi

# Apply Terraform
echo "🚀 Deploying infrastructure..."
terraform apply -auto-approve

# Get cluster info
echo "📊 Getting cluster information..."
aws eks update-kubeconfig --region $(terraform output -raw region) --name $(terraform output -raw cluster_name)

# Wait for cluster to be ready
echo "⏳ Waiting for cluster to be ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=300s

# Deploy Argo CD
echo "🔧 Deploying Argo CD..."
kubectl apply -f ../cluster-config/argo/argo-namespace.yaml
kubectl apply -f ../cluster-config/argo/values.yaml

# Wait for Argo CD to be ready
echo "⏳ Waiting for Argo CD to be ready..."
kubectl wait --for=condition=Available deployment/argocd-server -n argocd --timeout=300s

# Get Argo CD admin password
echo "🔑 Argo CD admin password:"
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
echo

# Deploy app-of-apps
echo "🚀 Deploying application of applications..."
kubectl apply -f ../cluster-config/apps/app-of-apps.yaml

echo "✅ Bootstrap complete!"
echo "🌐 Argo CD UI: https://$(kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')"
echo "🔑 Username: admin"
echo "📖 Next steps:"
echo "   1. Access Argo CD UI with the credentials above"
echo "   2. Update the placeholder values in Helm charts with actual values from Terraform outputs"
echo "   3. Monitor application sync status in Argo CD"
