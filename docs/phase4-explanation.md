# Phase 4: Compute Layer - Detailed Explanation

## Table of Contents
1. [Overview](#overview)
2. [What We're Building](#what-were-building)
3. [Concepts Explained](#concepts-explained)
4. [The Code Explained](#the-code-explained)
5. [Complete Architecture](#complete-architecture)
6. [The Full Request Flow](#the-full-request-flow)
7. [Cost](#cost)

---

## Overview

**Phase 4** creates the compute layer - where your application actually runs!

**What we create:**
- 1 ECR Repository (Docker image storage)
- 1 ALB (Application Load Balancer)
- 1 ECS Cluster + Service + Task Definition

**Estimated Cost:** ~$18-25/month

---

## What We're Building

| Component | Real-World Analogy |
|-----------|-------------------|
| **ECR** | A warehouse to store your Docker images |
| **ALB** | A receptionist who directs visitors to the right person |
| **ECS** | The workers (containers) doing the actual work |

---

## Concepts Explained

### 1. ECR (Elastic Container Registry)

**What is it?**

ECR is AWS's Docker image storage. Like Docker Hub, but private and inside AWS.

```
Your Computer                          AWS ECR
┌─────────────────┐                   ┌─────────────────────────────────┐
│                 │   docker push     │                                 │
│  Docker Image   │──────────────────▶│  devsecops-platform-dev:latest │
│  (your app)     │                   │  devsecops-platform-dev:v1.0.0 │
│                 │                   │  devsecops-platform-dev:v1.0.1 │
└─────────────────┘                   │  (keeps last 10 images)        │
                                      │                                 │
                                      │  🔐 Encrypted with KMS          │
                                      │  🔍 Scanned for vulnerabilities │
                                      └─────────────────────────────────┘
```

**Why not use Docker Hub?**
- ECR is **private** (only your AWS account can access)
- **Faster** pulls (same AWS network, via VPC Endpoint)
- **Integrated** with ECS (no separate login needed)
- **Encrypted** with your KMS key

---

### 2. ALB (Application Load Balancer)

**What is it?**

ALB is a "traffic cop" that receives all incoming requests and distributes them to your containers.

```
                                    ALB
Users ────────────▶ ┌─────────────────────────────────┐
                    │                                 │
 User 1 ──────────▶ │    "I'll send you to a        │ ────▶ Container 1
 User 2 ──────────▶ │     healthy container"         │ ────▶ Container 2
 User 3 ──────────▶ │                                 │ ────▶ Container 1
                    │                                 │
                    └─────────────────────────────────┘
```

**Why do we need ALB?**

| Without ALB | With ALB |
|-------------|----------|
| Users connect directly to container IP | Users connect to one ALB URL |
| If container dies, users get error | ALB routes to healthy container |
| Hard to scale (which IP?) | Easy scaling (ALB handles it) |
| No HTTPS termination | ALB handles SSL certificates |

**ALB Components:**

```
┌─────────────────────────────────────────────────────────────────────────┐
│                              ALB                                        │
│                                                                         │
│   ┌─────────────────────────────────────────────────────────────────┐   │
│   │  LISTENER (Port 80 - HTTP)                                      │   │
│   │                                                                 │   │
│   │  "When traffic arrives on port 80, forward to Target Group"     │   │
│   └─────────────────────────────────────────────────────────────────┘   │
│                                    │                                    │
│                                    ▼                                    │
│   ┌─────────────────────────────────────────────────────────────────┐   │
│   │  TARGET GROUP                                                   │   │
│   │                                                                 │   │
│   │  "These are the containers that can handle requests"            │   │
│   │                                                                 │   │
│   │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │   │
│   │  │ Container 1 │  │ Container 2 │  │ Container 3 │              │   │
│   │  │ 10.0.11.10  │  │ 10.0.11.20  │  │ 10.0.12.10  │              │   │
│   │  │  Healthy ✓  │  │  Healthy ✓  │  │ Unhealthy ✗ │              │   │
│   │  └─────────────┘  └─────────────┘  └─────────────┘              │   │
│   │                                                                 │   │
│   │  Health Check: GET /health every 30 seconds                     │   │
│   └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

---

### 3. ECS (Elastic Container Service)

**What is ECS?**

ECS runs your Docker containers. Instead of managing servers yourself, AWS handles everything.

**ECS with Fargate (Serverless containers):**

```
Traditional (EC2):                    Fargate (Serverless):
┌─────────────────────┐               ┌─────────────────────┐
│ You manage:         │               │ You manage:         │
│ ├── Server          │               │ └── Container only  │
│ ├── OS updates      │               │                     │
│ ├── Docker install  │               │ AWS manages:        │
│ ├── Security patches│               │ ├── Server          │
│ └── Container       │               │ ├── OS updates      │
│                     │               │ ├── Docker          │
│ 😓 Lots of work     │               │ └── Security        │
└─────────────────────┘               │                     │
                                      │ 😊 Just deploy!     │
                                      └─────────────────────┘
```

**ECS Components:**

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           ECS CLUSTER                                   │
│                    "devsecops-platform-dev"                             │
│                                                                         │
│   ┌─────────────────────────────────────────────────────────────────┐   │
│   │  TASK DEFINITION (like a recipe)                                │   │
│   │                                                                 │   │
│   │  "How to run my container"                                      │   │
│   │                                                                 │   │
│   │  - Image: ECR_URL:latest                                        │   │
│   │  - CPU: 256 (0.25 vCPU)                                         │   │
│   │  - Memory: 512 MB                                               │   │
│   │  - Port: 8000                                                   │   │
│   │  - Environment variables: DB_HOST, DB_PORT, DB_NAME             │   │
│   │  - Secrets: DB_USERNAME, DB_PASSWORD, SECRET_KEY                │   │
│   │  - Logs: Send to CloudWatch                                     │   │
│   │                                                                 │   │
│   └─────────────────────────────────────────────────────────────────┘   │
│                                    │                                    │
│                                    ▼                                    │
│   ┌─────────────────────────────────────────────────────────────────┐   │
│   │  SERVICE                                                        │   │
│   │                                                                 │   │
│   │  "Keep 1 container running at all times"                        │   │
│   │                                                                 │   │
│   │  - Desired count: 1                                             │   │
│   │  - Launch type: FARGATE                                         │   │
│   │  - Subnets: Private subnets                                     │   │
│   │  - Security group: App SG                                       │   │
│   │  - Load balancer: Connect to ALB                                │   │
│   │                                                                 │   │
│   └─────────────────────────────────────────────────────────────────┘   │
│                                    │                                    │
│                                    ▼                                    │
│   ┌─────────────────────────────────────────────────────────────────┐   │
│   │  RUNNING TASK (actual container)                                │   │
│   │                                                                 │   │
│   │  ┌───────────────────────────────────────┐                      │   │
│   │  │  Container: "app"                     │                      │   │
│   │  │  IP: 10.0.11.45                       │                      │   │
│   │  │  Status: RUNNING                      │                      │   │
│   │  │  Health: HEALTHY                      │                      │   │
│   │  └───────────────────────────────────────┘                      │   │
│   │                                                                 │   │
│   └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

---

### 4. Environment Variables vs Secrets

**Environment Variables** (non-sensitive):
```
DB_HOST=devsecops-platform-dev-postgres.xxx.rds.amazonaws.com
DB_PORT=5432
DB_NAME=appdb
ENVIRONMENT=dev
PORT=8000
```

**Secrets** (sensitive - from Secrets Manager):
```
DB_USERNAME=dbadmin                    ← From Secrets Manager
DB_PASSWORD=aX9#kL2$mN...              ← From Secrets Manager
SECRET_KEY=f8a3b2c1d4e5...             ← From Secrets Manager
```

ECS automatically fetches secrets and injects them as environment variables!

---

## The Code Explained

### ECR Module (`modules/ecr/main.tf`)

```hcl
resource "aws_ecr_repository" "main" {
  name                 = "${var.project_name}-${var.environment}"
  image_tag_mutability = "MUTABLE"  # Can overwrite :latest tag

  # Scan images for vulnerabilities when pushed
  image_scanning_configuration {
    scan_on_push = true
  }

  # Encrypt with our KMS key
  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = var.kms_key_arn
  }
}

# Auto-delete old images (keep only last 10)
resource "aws_ecr_lifecycle_policy" "main" {
  repository = aws_ecr_repository.main.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 10 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
      action = { type = "expire" }
    }]
  })
}
```

---

### ALB Module (`modules/alb/main.tf`)

```hcl
# The Load Balancer itself
resource "aws_lb" "main" {
  name               = "${var.project_name}-${var.environment}-alb"
  internal           = false              # Internet-facing
  load_balancer_type = "application"
  security_groups    = [var.security_group_id]  # ALB SG (80, 443 from internet)
  subnets            = var.public_subnet_ids    # Must be in PUBLIC subnets!
}

# Target Group - where to send traffic
resource "aws_lb_target_group" "main" {
  name        = "${var.project_name}-${var.environment}-tg"
  port        = 8000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"  # Fargate uses IP addresses

  # Health check - ALB checks if container is healthy
  health_check {
    enabled             = true
    path                = "/health"    # Your app must have this endpoint!
    interval            = 30           # Check every 30 seconds
    timeout             = 5            # Wait 5 seconds for response
    healthy_threshold   = 2            # 2 successes = healthy
    unhealthy_threshold = 3            # 3 failures = unhealthy
    matcher             = "200"        # Expect HTTP 200 response
  }
}

# Listener - what port to listen on
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}
```

---

### ECS Module (`modules/ecs/main.tf`)

```hcl
# Cluster - logical grouping
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-${var.environment}"
}

# Task Definition - the "recipe"
resource "aws_ecs_task_definition" "main" {
  family                   = "${var.project_name}-${var.environment}"
  network_mode             = "awsvpc"         # Required for Fargate
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.container_cpu     # 256 = 0.25 vCPU
  memory                   = var.container_memory  # 512 MB
  execution_role_arn       = var.execution_role_arn  # For pulling images, getting secrets
  task_role_arn            = var.task_role_arn       # For app runtime permissions

  container_definitions = jsonencode([{
    name  = "app"
    image = "${var.ecr_repository_url}:latest"

    portMappings = [{
      containerPort = var.app_port  # 8000
      hostPort      = var.app_port
      protocol      = "tcp"
    }]

    # Non-sensitive config
    environment = [
      { name = "ENVIRONMENT", value = var.environment },
      { name = "PORT", value = tostring(var.app_port) },
      { name = "DB_HOST", value = var.db_host },
      { name = "DB_PORT", value = tostring(var.db_port) },
      { name = "DB_NAME", value = var.db_name }
    ]

    # Sensitive config - pulled from Secrets Manager!
    secrets = [
      { name = "DB_USERNAME", valueFrom = "${var.db_secret_arn}:username::" },
      { name = "DB_PASSWORD", valueFrom = "${var.db_secret_arn}:password::" },
      { name = "SECRET_KEY", valueFrom = "${var.app_secret_arn}:secret_key::" }
    ]

    # Send logs to CloudWatch
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/ecs/${var.project_name}-${var.environment}"
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "ecs"
      }
    }

    # Container health check
    healthCheck = {
      command     = ["CMD-SHELL", "curl -f http://localhost:${var.app_port}/health || exit 1"]
      interval    = 30
      timeout     = 5
      retries     = 3
      startPeriod = 60  # Give app 60 seconds to start
    }

    essential = true
  }])
}

# Service - keeps containers running
resource "aws_ecs_service" "main" {
  name            = "${var.project_name}-${var.environment}"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.main.arn
  desired_count   = var.desired_count  # 1 container
  launch_type     = "FARGATE"

  # Network configuration
  network_configuration {
    subnets          = var.private_subnet_ids  # Run in PRIVATE subnets
    security_groups  = [var.security_group_id] # App SG
    assign_public_ip = false                   # No public IP needed!
  }

  # Connect to ALB
  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "app"
    container_port   = var.app_port
  }
}
```

---

## Complete Architecture

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                                    INTERNET                                     │
└───────────────────────────────────────┬─────────────────────────────────────────┘
                                        │
                                        ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                                     VPC                                         │
│                                                                                 │
│   ┌─────────────────────────────────────────────────────────────────────────┐   │
│   │                          PUBLIC SUBNET                                  │   │
│   │                                                                         │   │
│   │   ┌─────────────────────────────────────────────────────────────────┐   │   │
│   │   │                           ALB                                   │   │   │
│   │   │                                                                 │   │   │
│   │   │   DNS: devsecops-platform-dev-alb-xxx.us-east-1.elb.amazonaws  │   │   │
│   │   │   Listens on: Port 80 (HTTP)                                    │   │   │
│   │   │   Security Group: ALB SG (allows 80, 443 from internet)         │   │   │
│   │   │                                                                 │   │   │
│   │   └─────────────────────────────────┬───────────────────────────────┘   │   │
│   │                                     │                                   │   │
│   └─────────────────────────────────────┼───────────────────────────────────┘   │
│                                         │ Port 8000                             │
│                                         ▼                                       │
│   ┌─────────────────────────────────────────────────────────────────────────┐   │
│   │                          PRIVATE SUBNET                                 │   │
│   │                                                                         │   │
│   │   ┌─────────────────────────────────────────────────────────────────┐   │   │
│   │   │                    ECS FARGATE CONTAINER                        │   │   │
│   │   │                                                                 │   │   │
│   │   │   Image: ECR_URL:latest                                         │   │   │
│   │   │   CPU: 0.25 vCPU | Memory: 512 MB                               │   │   │
│   │   │   Port: 8000                                                    │   │   │
│   │   │   Security Group: App SG (allows 8000 from ALB only)            │   │   │
│   │   │                                                                 │   │   │
│   │   │   Environment:                                                  │   │   │
│   │   │     DB_HOST, DB_PORT, DB_NAME, DB_USERNAME, DB_PASSWORD         │   │   │
│   │   │                                                                 │   │   │
│   │   └─────────────────────────────────┬───────────────────────────────┘   │   │
│   │                                     │                                   │   │
│   │   ┌─────────────────┐               │                                   │   │
│   │   │  VPC Endpoints  │◀──────────────┤ (get secrets, pull images,        │   │
│   │   │  ECR, Secrets,  │               │  send logs)                       │   │
│   │   │  CloudWatch     │               │                                   │   │
│   │   └─────────────────┘               │                                   │   │
│   │                                     │                                   │   │
│   └─────────────────────────────────────┼───────────────────────────────────┘   │
│                                         │ Port 5432                             │
│                                         ▼                                       │
│   ┌─────────────────────────────────────────────────────────────────────────┐   │
│   │                           DATA SUBNET                                   │   │
│   │                                                                         │   │
│   │   ┌─────────────────────────────────────────────────────────────────┐   │   │
│   │   │                      RDS PostgreSQL                             │   │   │
│   │   │                                                                 │   │   │
│   │   │   Security Group: RDS SG (allows 5432 from App SG only)         │   │   │
│   │   │                                                                 │   │   │
│   │   └─────────────────────────────────────────────────────────────────┘   │   │
│   │                                                                         │   │
│   └─────────────────────────────────────────────────────────────────────────┘   │
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘

                    ┌─────────────────────────────────────────┐
                    │              AWS SERVICES               │
                    │          (Outside VPC)                  │
                    │                                         │
                    │   ┌─────────┐  ┌───────────────────┐    │
                    │   │   ECR   │  │  Secrets Manager  │    │
                    │   └─────────┘  └───────────────────┘    │
                    │   ┌─────────────────────────────────┐   │
                    │   │        CloudWatch Logs          │   │
                    │   └─────────────────────────────────┘   │
                    └─────────────────────────────────────────┘
```

---

## The Full Request Flow

```
STEP 1: User makes request
─────────────────────────────────────────────────────────────────────

User browser: GET http://alb-dns-name.amazonaws.com/api/users

                    │
                    ▼

STEP 2: ALB receives request
─────────────────────────────────────────────────────────────────────

ALB (in public subnet):
  - Receives on port 80
  - Checks: "Which container is healthy?"
  - Picks healthy container: 10.0.11.45

                    │
                    ▼

STEP 3: ALB forwards to ECS container
─────────────────────────────────────────────────────────────────────

Security Group check:
  - Traffic from ALB SG? ✓ YES
  - Port 8000? ✓ YES
  - ALLOWED!

Container receives request on port 8000

                    │
                    ▼

STEP 4: Container processes request
─────────────────────────────────────────────────────────────────────

FastAPI app:
  - Receives GET /api/users
  - Needs to query database
  - Uses DB_HOST, DB_USERNAME, DB_PASSWORD (injected by ECS)

                    │
                    ▼

STEP 5: Container connects to RDS
─────────────────────────────────────────────────────────────────────

Security Group check:
  - Traffic from App SG? ✓ YES
  - Port 5432? ✓ YES
  - ALLOWED!

RDS returns data

                    │
                    ▼

STEP 6: Response goes back
─────────────────────────────────────────────────────────────────────

Container → ALB → User

User receives: {"users": [...]}
```

---

## Cost

| Resource | Monthly Cost |
|----------|--------------|
| ECR (storage) | ~$0.10 (for small images) |
| ALB | ~$16 (hourly charge + data) |
| ECS Fargate (0.25 vCPU, 512MB, 24/7) | ~$9 |
| CloudWatch Logs | ~$0.50 |
| **Total Phase 4** | **~$25/month** |

**Note:** ECS cost can be reduced with auto-shutdown (Phase 9)!

---

## Important: No Docker Image Yet!

After deploying Phase 4, the ECS service will try to start but **FAIL** because:
- ECR repository exists but is **empty**
- No Docker image has been pushed yet

This is expected! In Phase 5, we'll:
1. Build the Docker image
2. Push to ECR
3. ECS will automatically pick it up

For now, you'll see the ECS service in a "pending" or "failing" state - that's normal!

---

## What's Next

In **Phase 5: Application**, we'll:
- Build the FastAPI application Docker image
- Push it to ECR
- ECS will automatically start running it!
