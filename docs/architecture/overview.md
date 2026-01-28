# Architecture Overview

## System Architecture

```
                    ┌─────────────────────────────────────────────────────────────┐
                    │                         AWS Cloud                           │
                    │                                                             │
     Internet       │   ┌─────────────────────────────────────────────────────┐   │
        │           │   │                    VPC (10.0.0.0/16)                │   │
        │           │   │                                                     │   │
        ▼           │   │   ┌───────────────────────────────────────────┐     │   │
   ┌─────────┐      │   │   │           Public Subnets (2 AZs)          │     │   │
   │   IGW   │◄─────┼───┼───┤                                           │     │   │
   └────┬────┘      │   │   │   ┌─────────────────────────────────┐     │     │   │
        │           │   │   │   │    Application Load Balancer    │     │     │   │
        │           │   │   │   │         (HTTP/HTTPS)            │     │     │   │
        │           │   │   │   └──────────────┬──────────────────┘     │     │   │
        │           │   │   └──────────────────┼────────────────────────┘     │   │
        │           │   │                      │                              │   │
        │           │   │   ┌──────────────────┼────────────────────────┐     │   │
        │           │   │   │           Private Subnets (2 AZs)         │     │   │
        │           │   │   │                  │                        │     │   │
        │           │   │   │   ┌──────────────▼──────────────────┐     │     │   │
        │           │   │   │   │      ECS Fargate Service        │     │     │   │
        │           │   │   │   │         (FastAPI App)           │     │     │   │
        │           │   │   │   └──────────────┬──────────────────┘     │     │   │
        │           │   │   │                  │                        │     │   │
        │           │   │   │   ┌──────────────┴──────────────────┐     │     │   │
        │           │   │   │   │        VPC Endpoints            │     │     │   │
        │           │   │   │   │  (ECR, Logs, Secrets Manager)   │     │     │   │
        │           │   │   │   └─────────────────────────────────┘     │     │   │
        │           │   │   └───────────────────────────────────────────┘     │   │
        │           │   │                                                     │   │
        │           │   │   ┌───────────────────────────────────────────┐     │   │
        │           │   │   │             Data Subnets (2 AZs)          │     │   │
        │           │   │   │                                           │     │   │
        │           │   │   │   ┌─────────────────────────────────┐     │     │   │
        │           │   │   │   │      RDS PostgreSQL             │     │     │   │
        │           │   │   │   │      (db.t3.micro)              │     │     │   │
        │           │   │   │   └─────────────────────────────────┘     │     │   │
        │           │   │   └───────────────────────────────────────────┘     │   │
        │           │   └─────────────────────────────────────────────────────┘   │
        │           │                                                             │
        │           │   ┌─────────────────────────────────────────────────────┐   │
        │           │   │                 Supporting Services                 │   │
        │           │   │                                                     │   │
        │           │   │   ┌────────┐  ┌────────┐  ┌────────┐  ┌──────────┐  │   │
        │           │   │   │  ECR   │  │  KMS   │  │Secrets │  │CloudWatch│  │   │
        │           │   │   │        │  │        │  │Manager │  │          │  │   │
        │           │   │   └────────┘  └────────┘  └────────┘  └──────────┘  │   │
        │           │   └─────────────────────────────────────────────────────┘   │
        │           └─────────────────────────────────────────────────────────────┘
        │
   ┌────┴────┐
   │ GitHub  │
   │ Actions │
   └─────────┘
```

## Components

### Networking
- **VPC**: 10.0.0.0/16 with DNS enabled
- **Subnets**: 6 subnets across 2 AZs (public, private, data)
- **VPC Endpoints**: Replace NAT Gateway for cost savings

### Compute
- **ECS Fargate**: Serverless container orchestration
- **ALB**: Application Load Balancer with health checks

### Database
- **RDS PostgreSQL**: Managed database with encryption

### Security
- **KMS**: Customer managed encryption keys
- **Secrets Manager**: Database credentials and app secrets
- **Security Groups**: Network-level access control
- **IAM**: Least-privilege roles

### CI/CD
- **GitHub Actions**: Automated testing and deployment
- **OIDC**: Secure AWS authentication without long-lived credentials

### Monitoring
- **CloudWatch**: Logs, metrics, alarms, and dashboards
- **SNS**: Email alerting

### Cost Optimization
- **Lambda Scheduler**: Auto scale down during off-hours
- **No NAT Gateway**: VPC Endpoints instead ($35/month savings)

## Network Flow

1. User request hits ALB via Internet Gateway
2. ALB forwards to ECS tasks in private subnets
3. ECS tasks connect to RDS in data subnets
4. ECS uses VPC Endpoints for AWS service access
5. Logs sent to CloudWatch via VPC Endpoint

## Security Layers

1. **Edge**: ALB with security groups (ports 80/443)
2. **Application**: ECS with security groups (port 8000 from ALB only)
3. **Database**: RDS with security groups (port 5432 from app only)
4. **Data**: KMS encryption for RDS and secrets
