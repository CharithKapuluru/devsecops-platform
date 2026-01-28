# Deployment Runbook

## Prerequisites

- AWS CLI configured with appropriate credentials
- Docker installed
- Terraform v1.5+ installed
- GitHub repository set up

## Initial Setup

### 1. Bootstrap Terraform State

```bash
./scripts/bootstrap.sh
```

This creates:
- S3 bucket for Terraform state
- DynamoDB table for state locking

### 2. Configure Backend

Update `terraform/environments/dev/main.tf` with the backend configuration output from bootstrap.

### 3. Create terraform.tfvars

```bash
cd terraform/environments/dev
cp example.tfvars terraform.tfvars
# Edit terraform.tfvars with your values
```

### 4. Deploy Infrastructure

```bash
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

### 5. Build and Deploy Application

```bash
./scripts/deploy.sh
```

## Manual Deployment

### Build Docker Image

```bash
cd app
docker build -t devsecops-platform:latest .
```

### Push to ECR

```bash
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REPO="${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/devsecops-platform-dev"

aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ECR_REPO
docker tag devsecops-platform:latest ${ECR_REPO}:latest
docker push ${ECR_REPO}:latest
```

### Update ECS Service

```bash
aws ecs update-service \
    --cluster devsecops-platform-dev \
    --service devsecops-platform-dev \
    --force-new-deployment
```

## Rollback

To rollback to a previous version:

1. Find the previous image tag in ECR
2. Update the ECS task definition with the previous image
3. Update the service

```bash
aws ecs update-service \
    --cluster devsecops-platform-dev \
    --service devsecops-platform-dev \
    --task-definition <previous-task-definition-arn>
```

## Troubleshooting

### Check ECS Service Status

```bash
aws ecs describe-services \
    --cluster devsecops-platform-dev \
    --services devsecops-platform-dev
```

### View ECS Task Logs

```bash
aws logs tail /ecs/devsecops-platform-dev --follow
```

### Check RDS Status

```bash
aws rds describe-db-instances \
    --db-instance-identifier devsecops-platform-dev-postgres
```
