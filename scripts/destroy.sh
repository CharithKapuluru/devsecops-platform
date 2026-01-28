#!/bin/bash
# Destroy script - Tears down all infrastructure
set -euo pipefail

echo "=== DevSecOps Platform Destroy ==="
echo "WARNING: This will destroy all infrastructure!"
echo ""
read -p "Are you sure you want to continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Aborted."
    exit 0
fi

AWS_REGION=${AWS_REGION:-us-east-1}

cd "$(dirname "$0")/../terraform/environments/dev"

echo "Running terraform destroy..."
terraform destroy -auto-approve

echo ""
echo "=== Infrastructure Destroyed ==="
echo ""
echo "Note: The bootstrap resources (S3 bucket, DynamoDB table) were NOT destroyed."
echo "To destroy bootstrap resources, run:"
echo "  cd terraform/bootstrap && terraform destroy"
