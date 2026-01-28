# DevSecOps Cloud Platform

A cost-optimized AWS cloud platform demonstrating DevSecOps best practices with FastAPI, PostgreSQL, and Terraform.

## Architecture

- **Application**: FastAPI with async PostgreSQL
- **Infrastructure**: 100% Terraform with reusable modules
- **CI/CD**: GitHub Actions with OIDC authentication
- **Security**: KMS encryption, Secrets Manager, least-privilege IAM
- **Monitoring**: CloudWatch logs, metrics, alarms, and dashboards
- **Cost Optimization**: Auto-shutdown scheduler, VPC Endpoints over NAT

## Project Structure

```
.
├── app/                      # FastAPI application
│   ├── src/
│   │   ├── api/              # API routes
│   │   ├── core/             # Configuration
│   │   ├── db/               # Database
│   │   ├── middleware/       # Security middleware
│   │   ├── models/           # SQLAlchemy models
│   │   ├── schemas/          # Pydantic schemas
│   │   └── tests/            # Test suite
│   ├── alembic/              # Database migrations
│   ├── Dockerfile
│   └── requirements.txt
├── terraform/
│   ├── bootstrap/            # State management (S3 + DynamoDB)
│   ├── environments/
│   │   └── dev/              # Dev environment configuration
│   └── modules/              # Reusable Terraform modules
│       ├── vpc/
│       ├── subnets/
│       ├── security-groups/
│       ├── kms/
│       ├── iam/
│       ├── vpc-endpoints/
│       ├── secrets/
│       ├── rds/
│       ├── ecr/
│       ├── alb/
│       ├── ecs/
│       ├── cloudwatch/
│       └── lambda-scheduler/
├── .github/workflows/        # CI/CD pipelines
├── scripts/                  # Utility scripts
└── docs/                     # Documentation
```

## Quick Start

### Prerequisites

- AWS CLI configured
- Terraform v1.5+
- Docker
- GitHub account

### 1. Bootstrap Terraform State

```bash
./scripts/bootstrap.sh
```

### 2. Configure Variables

```bash
cd terraform/environments/dev
cp example.tfvars terraform.tfvars
# Edit terraform.tfvars with your values
```

### 3. Deploy Infrastructure

```bash
cd terraform/environments/dev
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

### 4. Build and Deploy Application

```bash
./scripts/deploy.sh
```

### 5. Access Application

Get the ALB DNS name:
```bash
terraform output alb_dns_name
```

## Cost Management

### Estimated Monthly Cost: ~$30-45

| Component | Cost |
|-----------|------|
| VPC Endpoints | ~$7 |
| KMS | ~$1 |
| RDS (Free Tier) | $0-15 |
| ALB | ~$16 |
| ECS Fargate | ~$5-10 |
| CloudWatch | ~$3 |

### Auto-Shutdown (Saves ~40%)

Resources automatically scale down at 6 PM and up at 8 AM (EST).

Manual control:
```bash
./scripts/scale-down.sh  # Stop resources
./scripts/scale-up.sh    # Start resources
```

## Development

### Run Locally

```bash
cd app
pip install -r requirements.txt
DATABASE_URL="postgresql+asyncpg://user:pass@localhost:5432/db" \
SECRET_KEY="dev-secret" \
uvicorn src.main:app --reload
```

### Run Tests

```bash
cd app
pytest src/tests -v
```

### Lint Code

```bash
ruff check app/src
ruff format app/src
```

## CI/CD

- **CI**: Runs on all PRs (lint, test, security scan, terraform validate)
- **Build**: Builds Docker image and pushes to ECR on main branch
- **Deploy**: Updates ECS service with new image
- **Terraform**: Plans on PR, applies on main

## Security Features

- KMS encryption for data at rest
- Secrets Manager for sensitive configuration
- Security groups for network isolation
- IAM least-privilege roles
- GitHub OIDC (no long-lived credentials)
- Security headers middleware
- Semgrep and Trivy scanning in CI

## API Endpoints

- `GET /` - API info
- `GET /health` - Health check
- `GET /health/ready` - Readiness check
- `GET /api/v1/items` - List items
- `POST /api/v1/items` - Create item
- `GET /api/v1/items/{id}` - Get item
- `PATCH /api/v1/items/{id}` - Update item
- `DELETE /api/v1/items/{id}` - Delete item

## Documentation

- [Architecture Overview](docs/architecture/overview.md)
- [Deployment Runbook](docs/runbooks/deployment.md)
- [ADR: VPC Endpoints](docs/adr/001-vpc-endpoints-over-nat.md)
- [ADR: Cost Optimization](docs/adr/002-cost-optimization-strategy.md)

## Cleanup

```bash
./scripts/destroy.sh
```
