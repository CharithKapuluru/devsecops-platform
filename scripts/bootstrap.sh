#!/bin/bash
# Bootstrap script - Sets up Terraform state infrastructure
set -euo pipefail

echo "=== DevSecOps Platform Bootstrap ==="

# Check prerequisites
command -v terraform >/dev/null 2>&1 || { echo "Error: terraform is required"; exit 1; }
command -v aws >/dev/null 2>&1 || { echo "Error: aws CLI is required"; exit 1; }

# Get AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=${AWS_REGION:-us-east-1}

echo "AWS Account: $AWS_ACCOUNT_ID"
echo "AWS Region: $AWS_REGION"

cd "$(dirname "$0")/../terraform/bootstrap"

# Create tfvars file
cat > terraform.tfvars <<EOF
aws_region     = "$AWS_REGION"
aws_account_id = "$AWS_ACCOUNT_ID"
project_name   = "devsecops-platform"
EOF

echo "Created terraform.tfvars"

# Initialize and apply
terraform init
terraform plan -out=tfplan
terraform apply tfplan

echo ""
echo "=== Bootstrap Complete ==="
echo ""
echo "Next steps:"
echo "1. Update terraform/environments/dev/main.tf with the backend configuration"
echo "2. Run: cd terraform/environments/dev && terraform init"
