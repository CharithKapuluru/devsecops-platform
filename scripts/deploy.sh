#!/bin/bash
# Deploy script - Builds and deploys the application
set -euo pipefail

echo "=== DevSecOps Platform Deploy ==="

# Configuration
PROJECT_NAME="devsecops-platform"
ENVIRONMENT="dev"
AWS_REGION=${AWS_REGION:-us-east-1}

# Check prerequisites
command -v docker >/dev/null 2>&1 || { echo "Error: docker is required"; exit 1; }
command -v aws >/dev/null 2>&1 || { echo "Error: aws CLI is required"; exit 1; }

# Get ECR repository URL
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REPO="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${PROJECT_NAME}-${ENVIRONMENT}"

echo "Building and pushing to: $ECR_REPO"

# Login to ECR
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPO

# Build image
cd "$(dirname "$0")/../app"
docker build -t ${PROJECT_NAME}:latest .

# Tag and push
docker tag ${PROJECT_NAME}:latest ${ECR_REPO}:latest
docker tag ${PROJECT_NAME}:latest ${ECR_REPO}:$(git rev-parse --short HEAD)
docker push ${ECR_REPO}:latest
docker push ${ECR_REPO}:$(git rev-parse --short HEAD)

# Update ECS service
echo "Updating ECS service..."
aws ecs update-service \
    --cluster ${PROJECT_NAME}-${ENVIRONMENT} \
    --service ${PROJECT_NAME}-${ENVIRONMENT} \
    --force-new-deployment \
    --region $AWS_REGION

echo "Waiting for deployment to stabilize..."
aws ecs wait services-stable \
    --cluster ${PROJECT_NAME}-${ENVIRONMENT} \
    --services ${PROJECT_NAME}-${ENVIRONMENT} \
    --region $AWS_REGION

echo ""
echo "=== Deployment Complete ==="
