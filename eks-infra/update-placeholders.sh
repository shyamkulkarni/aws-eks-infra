#!/bin/bash
set -e

echo "🔧 Updating placeholder values in Helm charts..."

# Get Terraform outputs
cd infra
ACCOUNT_ID=$(terraform output -raw account_id)
VPC_ID=$(terraform output -raw vpc_id)
REGION=$(terraform output -raw region)
CLUSTER_NAME=$(terraform output -raw cluster_name)
cd ..

echo "📊 Terraform outputs:"
echo "   Account ID: $ACCOUNT_ID"
echo "   VPC ID: $VPC_ID"
echo "   Region: $REGION"
echo "   Cluster Name: $CLUSTER_NAME"

# Update cluster-autoscaler values
echo "🔄 Updating cluster-autoscaler values..."
sed -i.bak "s/ACCOUNT_ID_PLACEHOLDER/$ACCOUNT_ID/g" cluster-config/apps/addons/cluster-autoscaler/values.yaml
sed -i.bak "s/eks-gitops/$CLUSTER_NAME/g" cluster-config/apps/addons/cluster-autoscaler/values.yaml

# Update aws-load-balancer-controller values
echo "🔄 Updating aws-load-balancer-controller values..."
sed -i.bak "s/ACCOUNT_ID_PLACEHOLDER/$ACCOUNT_ID/g" cluster-config/apps/addons/aws-load-balancer-controller/values.yaml
sed -i.bak "s/VPC_ID_PLACEHOLDER/$VPC_ID/g" cluster-config/apps/addons/aws-load-balancer-controller/values.yaml
sed -i.bak "s/eks-gitops/$CLUSTER_NAME/g" cluster-config/apps/addons/aws-load-balancer-controller/values.yaml

# Update external-dns values
echo "🔄 Updating external-dns values..."
sed -i.bak "s/ACCOUNT_ID_PLACEHOLDER/$ACCOUNT_ID/g" cluster-config/apps/addons/external-dns/values.yaml

# Clean up backup files
echo "🧹 Cleaning up backup files..."
find cluster-config -name "*.bak" -delete

echo "✅ Placeholder values updated successfully!"
echo "📝 Next steps:"
echo "   1. Commit and push the updated values to your repository"
echo "   2. Argo CD will automatically sync the updated applications"
echo "   3. Monitor the sync status in Argo CD UI"
