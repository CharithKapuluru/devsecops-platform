#!/bin/bash
# Scale up script - Manually scale up ECS and RDS
set -euo pipefail

PROJECT_NAME="devsecops-platform"
ENVIRONMENT="dev"
AWS_REGION=${AWS_REGION:-us-east-1}

echo "=== Scaling Up ==="

# Scale up ECS
echo "Scaling up ECS service..."
aws ecs update-service \
    --cluster ${PROJECT_NAME}-${ENVIRONMENT} \
    --service ${PROJECT_NAME}-${ENVIRONMENT} \
    --desired-count 1 \
    --region $AWS_REGION

# Start RDS
echo "Starting RDS instance..."
aws rds start-db-instance \
    --db-instance-identifier ${PROJECT_NAME}-${ENVIRONMENT}-postgres \
    --region $AWS_REGION 2>/dev/null || echo "RDS may already be running"

echo "Scale up initiated. Resources may take a few minutes to become available."
