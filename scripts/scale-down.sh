#!/bin/bash
# Scale down script - Manually scale down ECS and RDS to save costs
set -euo pipefail

PROJECT_NAME="devsecops-platform"
ENVIRONMENT="dev"
AWS_REGION=${AWS_REGION:-us-east-1}

echo "=== Scaling Down ==="

# Scale down ECS
echo "Scaling down ECS service..."
aws ecs update-service \
    --cluster ${PROJECT_NAME}-${ENVIRONMENT} \
    --service ${PROJECT_NAME}-${ENVIRONMENT} \
    --desired-count 0 \
    --region $AWS_REGION

# Stop RDS
echo "Stopping RDS instance..."
aws rds stop-db-instance \
    --db-instance-identifier ${PROJECT_NAME}-${ENVIRONMENT}-postgres \
    --region $AWS_REGION 2>/dev/null || echo "RDS may already be stopped"

echo "Scale down initiated. This will save costs while resources are not in use."
