# Decoupled Retail Store Deployment Guide

## Architecture Overview
- **Frontend**: React app hosted on AWS Amplify
- **Static Assets**: S3 bucket with CloudFront CDN
- **Backend APIs**: Microservices running in EKS
- **Load Balancer**: ALB for backend API routing

## Deployment Steps

### 1. Deploy Infrastructure
```bash
cd infra/
terraform init
terraform plan
terraform apply
```

### 2. Get Infrastructure Outputs
```bash
terraform output
```

### 3. Upload Static Assets to S3
```bash
cd ../assets/
./upload-assets.sh $(terraform output -raw s3_bucket_name)
```

### 4. Deploy Backend to EKS
```bash
cd ../cluster-config/
kubectl apply -f apps/retail-store.yaml
```

### 5. Trigger Amplify Build
The Amplify app will automatically build and deploy when you push to the main branch.

## URLs
- **Frontend**: `https://main.{amplify-app-id}.amplifyapp.com`
- **Static Assets**: `https://{cloudfront-domain}`
- **Backend API**: `https://{alb-dns-name}`

## Environment Variables
- `REACT_APP_API_URL`: Backend API endpoint
- `REACT_APP_ASSETS_URL`: CloudFront URL for static assets