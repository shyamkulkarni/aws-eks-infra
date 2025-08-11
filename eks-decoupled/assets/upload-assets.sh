#!/bin/bash

# Script to upload static assets to S3 bucket
# Usage: ./upload-assets.sh <bucket-name>

BUCKET_NAME=$1

if [ -z "$BUCKET_NAME" ]; then
    echo "Usage: $0 <bucket-name>"
    echo "Get bucket name from: terraform output s3_bucket_name"
    exit 1
fi

echo "Uploading assets to S3 bucket: $BUCKET_NAME"

# Upload images
aws s3 cp images/ s3://$BUCKET_NAME/images/ --recursive --acl public-read

# Upload any other static assets
if [ -d "css" ]; then
    aws s3 cp css/ s3://$BUCKET_NAME/css/ --recursive --acl public-read
fi

if [ -d "js" ]; then
    aws s3 cp js/ s3://$BUCKET_NAME/js/ --recursive --acl public-read
fi

echo "Assets uploaded successfully!"
echo "CloudFront URL: $(terraform output -raw cloudfront_url)"