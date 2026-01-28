# Phase 2: Security Foundation - Detailed Explanation

## Table of Contents
1. [Overview](#overview)
2. [What We're Building](#what-were-building)
3. [Concepts Explained](#concepts-explained)
4. [The Code Explained](#the-code-explained)
5. [Architecture Diagram](#architecture-diagram)
6. [Why These Specific Choices?](#why-these-specific-choices)
7. [Deployment Steps](#deployment-steps)
8. [Verification Checklist](#verification-checklist)
9. [Cost](#cost)

---

## Overview

**Phase 2** creates the security infrastructure for your platform. Think of Phase 1 as building the walls of your house - Phase 2 adds the locks, security cameras, ID cards, and private tunnels.

**What we create:**
- 1 KMS Key (encryption key)
- 3 IAM Roles (permission sets)
- 4 Security Groups (firewalls)
- 5 VPC Endpoints (private tunnels to AWS services)

**Estimated Cost:** ~$8/month (mostly VPC Endpoints)

---

## What We're Building

| AWS Service | Real-World Analogy |
|-------------|-------------------|
| **KMS Key** | Master lock that encrypts everything |
| **IAM Roles** | ID badges with specific access permissions |
| **Security Groups** | Firewalls / Bouncers at doors |
| **VPC Endpoints** | Private underground tunnels to AWS services |

---

## Concepts Explained

### 1. KMS (Key Management Service)

**What is encryption?**
```
Original data:     "my-password-123"
                         ↓
                   [Encryption with KMS key]
                         ↓
Encrypted data:    "aGVsbG8gd29ybGQ="  (unreadable gibberish)
```

If someone steals your database, they only get gibberish - useless without the KMS key!

**KMS Key** is a master encryption key managed by AWS that:
- Encrypts your database (RDS)
- Encrypts your secrets (Secrets Manager)
- Encrypts your logs (CloudWatch)
- Auto-rotates yearly (security best practice)

**Why not just use a password?**
| Regular Password | KMS Key |
|------------------|---------|
| Stored in code (risky!) | Stored securely in AWS |
| Never rotates | Auto-rotates yearly |
| You manage it | AWS manages it |
| Can be leaked | Hardware-protected |

---

### 2. IAM Roles (Identity and Access Management)

**The Problem:** Your ECS containers need to:
- Pull Docker images from ECR
- Read secrets from Secrets Manager
- Write logs to CloudWatch

**But how?** You can't put AWS access keys in your code (security risk!).

**Solution: IAM Roles** - Like an ID badge that automatically grants permissions.

```
┌─────────────────────────────────────────────────────────────┐
│                     IAM ROLE ANALOGY                        │
│                                                             │
│   Think of a HOSPITAL:                                      │
│                                                             │
│   👨‍⚕️ Doctor Badge (ECS Task Role)                          │
│      - Can access patient records                           │
│      - Can write prescriptions                              │
│      - Cannot access billing system                         │
│                                                             │
│   👩‍💼 Admin Badge (ECS Execution Role)                       │
│      - Can unlock medicine cabinets (pull images)           │
│      - Can access secure storage (get secrets)              │
│      - Cannot treat patients                                │
│                                                             │
│   🔧 Maintenance Badge (GitHub Actions Role)                │
│      - Can enter through service entrance (OIDC)            │
│      - Can update equipment (deploy code)                   │
│      - Cannot access patient data                           │
└─────────────────────────────────────────────────────────────┘
```

**We create 3 roles:**

| Role | Who Uses It | What It Can Do |
|------|-------------|----------------|
| **ECS Execution Role** | ECS service (AWS) | Pull images, get secrets, start containers |
| **ECS Task Role** | Your application code | Read secrets, write logs |
| **GitHub Actions Role** | CI/CD pipeline | Push images, deploy to ECS |

---

### 3. Security Groups (Virtual Firewalls)

**What is a Security Group?**

A security group is a **firewall** that controls what traffic can enter and exit your resources.

```
                    INTERNET
                        │
                        ▼
    ┌───────────────────────────────────────┐
    │         ALB SECURITY GROUP            │
    │  ┌─────────────────────────────────┐  │
    │  │ INBOUND RULES:                  │  │
    │  │  ✓ Port 80 (HTTP) from anywhere │  │
    │  │  ✓ Port 443 (HTTPS) from anywhere│  │
    │  │  ✗ Everything else BLOCKED      │  │
    │  └─────────────────────────────────┘  │
    │                  │                    │
    │           [ALB Resource]              │
    │                  │                    │
    │  ┌─────────────────────────────────┐  │
    │  │ OUTBOUND RULES:                 │  │
    │  │  ✓ All traffic allowed          │  │
    │  └─────────────────────────────────┘  │
    └───────────────────────────────────────┘
                        │
                        ▼
    ┌───────────────────────────────────────┐
    │         APP SECURITY GROUP            │
    │  ┌─────────────────────────────────┐  │
    │  │ INBOUND RULES:                  │  │
    │  │  ✓ Port 8000 from ALB SG ONLY   │  │
    │  │  ✗ Everything else BLOCKED      │  │
    │  │  ✗ Direct internet = BLOCKED!   │  │
    │  └─────────────────────────────────┘  │
    └───────────────────────────────────────┘
                        │
                        ▼
    ┌───────────────────────────────────────┐
    │         RDS SECURITY GROUP            │
    │  ┌─────────────────────────────────┐  │
    │  │ INBOUND RULES:                  │  │
    │  │  ✓ Port 5432 from APP SG ONLY   │  │
    │  │  ✗ Everything else BLOCKED      │  │
    │  │  ✗ ALB cannot access = BLOCKED! │  │
    │  │  ✗ Internet = BLOCKED!          │  │
    │  └─────────────────────────────────┘  │
    └───────────────────────────────────────┘
```

**Key Security Concept:** Each layer can ONLY talk to the layer directly above/below it!

| Security Group | Allows Inbound From | Purpose |
|----------------|---------------------|---------|
| **ALB SG** | Internet (0.0.0.0/0) on 80, 443 | Accept web traffic |
| **App SG** | ALB SG only on port 8000 | Only ALB can reach app |
| **RDS SG** | App SG only on port 5432 | Only app can reach database |
| **VPC Endpoints SG** | VPC CIDR on port 443 | Internal AWS service access |

---

### 4. VPC Endpoints (Private AWS Service Access)

**The Problem:**

Your ECS containers are in a **private subnet** (no internet access). But they need to:
- Pull Docker images from ECR
- Send logs to CloudWatch
- Get secrets from Secrets Manager

**Old Solution: NAT Gateway**
```
Private Subnet → NAT Gateway → Internet → ECR/CloudWatch/etc.
                    │
              Costs $35/month!
```

**Better Solution: VPC Endpoints**
```
Private Subnet → VPC Endpoint → ECR/CloudWatch/etc. (directly!)
                    │
              Costs ~$7/month (saves $28!)
              + More secure (traffic never leaves AWS network)
```

**Types of VPC Endpoints:**

| Type | How It Works | Cost |
|------|--------------|------|
| **Gateway Endpoint** | Adds route to route table | FREE |
| **Interface Endpoint** | Creates private IP in subnet | ~$7.20/month each |

**Our VPC Endpoints:**

| Endpoint | Type | Purpose |
|----------|------|---------|
| **S3** | Gateway (FREE) | Store Docker image layers |
| **ECR API** | Interface | Docker login authentication |
| **ECR DKR** | Interface | Docker image pull |
| **CloudWatch Logs** | Interface | Send application logs |
| **Secrets Manager** | Interface | Get database credentials |

---

### 5. GitHub Actions OIDC (OpenID Connect)

**The Old (Bad) Way:**
```
GitHub Actions workflow:
  - Uses AWS_ACCESS_KEY_ID: AKIA...
  - Uses AWS_SECRET_ACCESS_KEY: wJalr...

Problems:
  ✗ Long-lived credentials (can be stolen)
  ✗ Stored in GitHub secrets (another attack surface)
  ✗ Never expire unless manually rotated
```

**The New (Secure) Way - OIDC:**
```
GitHub Actions workflow:
  1. GitHub says: "I am repo:user/repo-name running workflow"
  2. AWS says: "Let me verify that with GitHub..."
  3. GitHub confirms: "Yes, that's my workflow"
  4. AWS says: "OK, here's a temporary credential (expires in 1 hour)"

Benefits:
  ✓ No stored credentials
  ✓ Temporary tokens (expire automatically)
  ✓ Tied to specific repo (can't be used elsewhere)
```

```
┌─────────────┐     1. Request token      ┌─────────────┐
│   GitHub    │ ─────────────────────────▶│     AWS     │
│   Actions   │                           │    IAM      │
│             │◀───────────────────────── │             │
└─────────────┘     4. Temporary creds    └──────┬──────┘
                                                 │
                                          2. Verify │
                                                 │
                                                 ▼
                                          ┌─────────────┐
                                          │   GitHub    │
                                          │    OIDC     │
                                          │   Provider  │
                                          └─────────────┘
                                                 │
                                          3. Confirmed! │
                                                 ▲
                                                 │
```

---

## The Code Explained

### KMS Module (`modules/kms/main.tf`)

```hcl
resource "aws_kms_key" "main" {
  description             = "KMS key for ${var.project_name} ${var.environment}"
  deletion_window_in_days = 7           # Wait 7 days before actually deleting (safety)
  enable_key_rotation     = true        # Auto-rotate yearly (security best practice)
  multi_region            = false       # Single region (cost savings)

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Allow your AWS account full access to manage this key
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        # Allow CloudWatch Logs service to use this key
        Sid    = "Allow CloudWatch Logs"
        Effect = "Allow"
        Principal = {
          Service = "logs.amazonaws.com"
        }
        Action = [
          "kms:Encrypt*",
          "kms:Decrypt*",
          "kms:GenerateDataKey*"
        ]
        Resource = "*"
      },
      {
        # Allow RDS service to use this key
        Sid    = "Allow RDS"
        Effect = "Allow"
        Principal = {
          Service = "rds.amazonaws.com"
        }
        Action = [
          "kms:Encrypt*",
          "kms:Decrypt*",
          "kms:GenerateDataKey*"
        ]
        Resource = "*"
      }
    ]
  })
}

# Create a human-readable alias (name) for the key
resource "aws_kms_alias" "main" {
  name          = "alias/${var.project_name}-${var.environment}"
  target_key_id = aws_kms_key.main.key_id
}
```

**What each part does:**

| Setting | What It Does |
|---------|--------------|
| `deletion_window_in_days = 7` | Accidental delete protection - you have 7 days to cancel |
| `enable_key_rotation = true` | AWS automatically creates new key material yearly |
| `policy` | Who is allowed to use this key |

---

### Security Groups (`modules/security-groups/main.tf`)

```hcl
# ALB Security Group - The front door
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-${var.environment}-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = var.vpc_id

  # INBOUND: Who can connect TO the ALB
  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]    # Anyone on internet
  }

  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]    # Anyone on internet
  }

  # OUTBOUND: Where can ALB send traffic TO
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"             # -1 means all protocols
    cidr_blocks = ["0.0.0.0/0"]    # Anywhere
  }
}

# App Security Group - Only accepts traffic FROM ALB
resource "aws_security_group" "app" {
  name   = "${var.project_name}-${var.environment}-app-sg"
  vpc_id = var.vpc_id

  ingress {
    description     = "Traffic from ALB"
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]  # ONLY from ALB SG!
  }
  # Note: No cidr_blocks - can't be accessed directly from internet!
}

# RDS Security Group - Only accepts traffic FROM App
resource "aws_security_group" "rds" {
  name   = "${var.project_name}-${var.environment}-rds-sg"
  vpc_id = var.vpc_id

  ingress {
    description     = "PostgreSQL from application"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]  # ONLY from App SG!
  }
}
```

**Security Group Reference:**

Notice how App SG references ALB SG:
```hcl
security_groups = [aws_security_group.alb.id]
```

This is more secure than using IP addresses because:
- If ALB's IP changes, it still works
- Only traffic originating FROM resources with ALB SG is allowed

---

### VPC Endpoints (`modules/vpc-endpoints/main.tf`)

```hcl
# S3 Gateway Endpoint (FREE!)
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"              # Gateway = FREE
  route_table_ids   = [var.private_route_table_id]  # Add to route table
}

# ECR API Interface Endpoint
resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.ecr.api"
  vpc_endpoint_type   = "Interface"          # Interface = ~$7/month
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [var.vpc_endpoint_sg_id]
  private_dns_enabled = true                 # Use normal DNS names (ecr.us-east-1.amazonaws.com)
}
```

**Gateway vs Interface Endpoints:**

| Gateway Endpoint | Interface Endpoint |
|------------------|-------------------|
| Adds route to route table | Creates ENI (network interface) in subnet |
| Works with S3, DynamoDB only | Works with most AWS services |
| FREE | ~$7.20/month + data transfer |
| No security group needed | Needs security group |

---

### IAM Roles (`modules/iam/main.tf`)

```hcl
# ECS Execution Role - Used by ECS service to manage containers
resource "aws_iam_role" "ecs_execution" {
  name = "${var.project_name}-${var.environment}-ecs-execution"

  # Trust policy: WHO can assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"  # Only ECS service can use this role
        }
      }
    ]
  })
}

# Attach AWS managed policy for basic ECS permissions
resource "aws_iam_role_policy_attachment" "ecs_execution_policy" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Add custom permissions for secrets
resource "aws_iam_role_policy" "ecs_execution_secrets" {
  name = "secrets-access"
  role = aws_iam_role.ecs_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["secretsmanager:GetSecretValue"]
        Resource = var.secrets_manager_arn    # Only specific secrets, not all!
      },
      {
        Effect = "Allow"
        Action = ["kms:Decrypt"]
        Resource = var.kms_key_arn            # Only our KMS key, not all!
      }
    ]
  })
}
```

**Understanding IAM Policy Structure:**

```
Effect: "Allow" or "Deny"
Action: What operations (secretsmanager:GetSecretValue)
Resource: Which specific resources (arn:aws:secretsmanager:...:secret:my-project/*)

Principle of Least Privilege:
✓ secretsmanager:GetSecretValue on "my-project/*"  (GOOD - specific)
✗ secretsmanager:* on "*"                          (BAD - too broad)
```

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                                    VPC                                          │
│                                                                                 │
│  ┌────────────────────────────────────────────────────────────────────────────┐ │
│  │                           SECURITY GROUPS                                  │ │
│  │                                                                            │ │
│  │  ┌─────────────┐     ┌─────────────┐     ┌─────────────┐                  │ │
│  │  │   ALB SG    │────▶│   APP SG    │────▶│   RDS SG    │                  │ │
│  │  │  80, 443    │     │    8000     │     │    5432     │                  │ │
│  │  │  from any   │     │  from ALB   │     │  from APP   │                  │ │
│  │  └─────────────┘     └─────────────┘     └─────────────┘                  │ │
│  │                                                                            │ │
│  │                      ┌─────────────┐                                       │ │
│  │                      │  VPCE SG    │                                       │ │
│  │                      │    443      │                                       │ │
│  │                      │  from VPC   │                                       │ │
│  │                      └─────────────┘                                       │ │
│  └────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                 │
│  ┌────────────────────────────────────────────────────────────────────────────┐ │
│  │                            VPC ENDPOINTS                                   │ │
│  │                                                                            │ │
│  │  ┌───────────┐  ┌───────────┐  ┌───────────┐  ┌───────────┐  ┌──────────┐ │ │
│  │  │    S3     │  │  ECR API  │  │  ECR DKR  │  │   Logs    │  │ Secrets  │ │ │
│  │  │ (Gateway) │  │(Interface)│  │(Interface)│  │(Interface)│  │(Interface│ │ │
│  │  │   FREE    │  │  ~$7/mo   │  │  ~$7/mo   │  │  ~$7/mo   │  │  ~$7/mo  │ │ │
│  │  └───────────┘  └───────────┘  └───────────┘  └───────────┘  └──────────┘ │ │
│  └────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                 │
│  ┌────────────────────────────────────────────────────────────────────────────┐ │
│  │                              IAM ROLES                                     │ │
│  │                                                                            │ │
│  │  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐         │ │
│  │  │ ECS Execution    │  │   ECS Task       │  │ GitHub Actions   │         │ │
│  │  │                  │  │                  │  │                  │         │ │
│  │  │ - Pull ECR images│  │ - Read secrets   │  │ - Push to ECR    │         │ │
│  │  │ - Get secrets    │  │ - Write logs     │  │ - Deploy to ECS  │         │ │
│  │  │ - Start tasks    │  │                  │  │ - Update service │         │ │
│  │  └──────────────────┘  └──────────────────┘  └──────────────────┘         │ │
│  └────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                 │
│  ┌────────────────────────────────────────────────────────────────────────────┐ │
│  │                               KMS KEY                                      │ │
│  │                                                                            │ │
│  │              🔐 Encrypts: RDS, Secrets Manager, CloudWatch Logs            │ │
│  │              🔄 Auto-rotates yearly                                        │ │
│  └────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
```

---

## Why These Specific Choices?

### 1. Why 4 Interface Endpoints (~$28/month) instead of NAT Gateway ($35/month)?

| NAT Gateway | VPC Endpoints |
|-------------|---------------|
| $35/month + data charges | ~$28/month for 4 endpoints |
| Traffic goes to internet | Traffic stays in AWS network |
| Single point of failure | Redundant across AZs |
| Less secure | More secure |

**We save ~$7/month AND get better security!**

### 2. Why separate ECS Execution vs Task roles?

| ECS Execution Role | ECS Task Role |
|--------------------|---------------|
| Used by AWS ECS service | Used by your application code |
| Runs BEFORE container starts | Runs WHILE container is running |
| Pulls images, gets secrets to inject | Your app's runtime permissions |

Separation allows **least privilege** - each role only has what it needs.

### 3. Why OIDC instead of access keys for GitHub Actions?

| Access Keys | OIDC |
|-------------|------|
| Long-lived (until rotated) | Temporary (1 hour) |
| Can be stolen and reused | Tied to specific repo |
| Stored in GitHub | No credentials stored |
| You manage rotation | Automatic |

OIDC is the **industry standard** for CI/CD security.

---

## Deployment Steps

### Step 1: Update deploy_up_to_phase

Edit `terraform/environments/dev/terraform.tfvars`:

```hcl
deploy_up_to_phase = 2  # Changed from 1 to 2
```

### Step 2: Review the plan

```bash
cd terraform/environments/dev
terraform plan
```

### Step 3: Apply

```bash
terraform apply
```

---

## Verification Checklist

After deployment, verify in AWS Console:

### KMS Console
- [ ] Key named `alias/devsecops-platform-dev` exists
- [ ] Key rotation is enabled

### IAM Console
- [ ] Role `devsecops-platform-dev-ecs-execution` exists
- [ ] Role `devsecops-platform-dev-ecs-task` exists
- [ ] Role `devsecops-platform-dev-github-actions` exists
- [ ] OIDC Provider for `token.actions.githubusercontent.com` exists

### VPC Console → Security Groups
- [ ] `devsecops-platform-dev-alb-sg` (ports 80, 443)
- [ ] `devsecops-platform-dev-app-sg` (port 8000 from ALB)
- [ ] `devsecops-platform-dev-rds-sg` (port 5432 from App)
- [ ] `devsecops-platform-dev-vpce-sg` (port 443 from VPC)

### VPC Console → Endpoints
- [ ] S3 Gateway endpoint
- [ ] ECR API Interface endpoint
- [ ] ECR DKR Interface endpoint
- [ ] CloudWatch Logs Interface endpoint
- [ ] Secrets Manager Interface endpoint

---

## Cost

| Resource | Monthly Cost |
|----------|--------------|
| KMS Key | ~$1.00 |
| IAM Roles | Free |
| Security Groups | Free |
| S3 Gateway Endpoint | Free |
| ECR API Endpoint | ~$7.20 |
| ECR DKR Endpoint | ~$7.20 |
| Logs Endpoint | ~$7.20 |
| Secrets Manager Endpoint | ~$7.20 |
| **Total Phase 2** | **~$30/month** |

**Note:** Interface endpoints are $0.01/hour = $7.20/month each, plus $0.01/GB data processed.

Actually, let me recalculate more accurately:
- 4 Interface Endpoints × $0.01/hour × 730 hours = **$29.20/month**
- KMS Key = **$1/month**
- **Total: ~$30/month**

This is still cheaper than a NAT Gateway ($35 + data transfer)!

---

## What's Next

In **Phase 3: Data Layer**, we'll create:
- **Secrets Manager** - Store database credentials securely
- **RDS PostgreSQL** - Managed database in data subnets

The security infrastructure we just created will:
- Encrypt the database with our KMS key
- Allow ECS to read secrets using IAM roles
- Protect the database with RDS security group
