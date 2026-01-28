# Phase 5: Application - Detailed Explanation

## Table of Contents
1. [Overview](#overview)
2. [What We're Doing](#what-were-doing)
3. [The Application Code](#the-application-code)
4. [Building and Pushing to ECR](#building-and-pushing-to-ecr)
5. [How ECS Gets the Image](#how-ecs-gets-the-image)
6. [Deployment Steps](#deployment-steps)

---

## Overview

**Phase 5** is about the **application code** - no Terraform! We need to:

1. Build a Docker image of our FastAPI app
2. Push it to ECR (created in Phase 4)
3. ECS will automatically pull and run it

**Cost:** $0 (just your computer's electricity!)

---

## What We're Doing

```
┌─────────────────┐         ┌─────────────────┐         ┌─────────────────┐
│  Your Computer  │         │      ECR        │         │      ECS        │
│                 │         │                 │         │                 │
│  1. Build image │────────▶│  2. Store image │────────▶│  3. Run image   │
│                 │  push   │                 │  pull   │                 │
│                 │         │                 │         │                 │
└─────────────────┘         └─────────────────┘         └─────────────────┘
```

---

## The Application Code

### Project Structure

```
app/
├── src/
│   ├── main.py           # FastAPI app entry point
│   ├── core/
│   │   └── config.py     # Settings (loads from env vars)
│   ├── api/
│   │   └── routes.py     # API endpoints
│   ├── db/
│   │   └── database.py   # Database connection
│   ├── models/           # SQLAlchemy models
│   ├── schemas/          # Pydantic schemas
│   ├── middleware/       # Security middleware
│   └── tests/            # Unit tests
├── Dockerfile            # How to build the image
├── requirements.txt      # Python dependencies
└── alembic/              # Database migrations
```

### Key Files Explained

#### `main.py` - The Entry Point

```python
from fastapi import FastAPI

app = FastAPI(title="DevSecOps Platform API")

@app.get("/health")
async def health_check():
    """ALB checks this endpoint to know if container is healthy"""
    return {"status": "healthy"}

@app.get("/health/ready")
async def readiness_check():
    """Check if app can connect to database"""
    db_healthy = await check_db_connection()
    return {"status": "ready" if db_healthy else "not_ready"}
```

The `/health` endpoint is **critical** - ALB uses it to check if your container is alive!

#### `config.py` - Settings from Environment

```python
class Settings(BaseSettings):
    # These come from ECS Task Definition (environment + secrets)
    DB_HOST: str = "localhost"
    DB_PORT: int = 5432
    DB_NAME: str = "appdb"
    DB_USERNAME: str = ""      # From Secrets Manager
    DB_PASSWORD: str = ""      # From Secrets Manager
    SECRET_KEY: str = ""       # From Secrets Manager
```

Your app reads configuration from **environment variables** - which ECS injects automatically!

#### `Dockerfile` - Build Instructions

```dockerfile
# Stage 1: Build (install dependencies)
FROM python:3.12-slim as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt

# Stage 2: Production (smaller image)
FROM python:3.12-slim
WORKDIR /app

# Copy dependencies from builder
COPY --from=builder /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages

# Copy app code
COPY . .

# Run as non-root user (security!)
USER appuser

# Health check
HEALTHCHECK --interval=30s --timeout=5s \
    CMD curl -f http://localhost:8000/health || exit 1

# Start the app
CMD ["uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

**Multi-stage build** = smaller final image (only runtime, no build tools)

---

## Building and Pushing to ECR

### Step 1: Login to ECR

```bash
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 501894534533.dkr.ecr.us-east-1.amazonaws.com
```

This gets a temporary password from AWS and logs Docker into your ECR.

### Step 2: Build the Image

```bash
cd app
docker build -t devsecops-platform-dev .
```

This runs the Dockerfile and creates an image on your computer.

### Step 3: Tag the Image

```bash
docker tag devsecops-platform-dev:latest 501894534533.dkr.ecr.us-east-1.amazonaws.com/devsecops-platform-dev:latest
```

Tags tell Docker where to push the image.

### Step 4: Push to ECR

```bash
docker push 501894534533.dkr.ecr.us-east-1.amazonaws.com/devsecops-platform-dev:latest
```

Uploads your image to ECR.

---

## How ECS Gets the Image

```
BEFORE (Phase 4 - no image):
┌─────────────────────────────────────────────────────────────────┐
│  ECS Service                                                    │
│                                                                 │
│  Task tries to start...                                         │
│  → Pull image from ECR                                          │
│  → ECR says "No image found!"                                   │
│  → Task FAILS ❌                                                 │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘


AFTER (Phase 5 - image pushed):
┌─────────────────────────────────────────────────────────────────┐
│  ECS Service                                                    │
│                                                                 │
│  Task tries to start...                                         │
│  → Pull image from ECR                                          │
│  → ECR returns image ✓                                          │
│  → ECS injects environment variables and secrets                │
│  → Container starts on port 8000                                │
│  → ALB health check passes ✓                                    │
│  → Task RUNNING! ✅                                              │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### What ECS Does Automatically

1. **Pulls image** from ECR (via VPC Endpoint)
2. **Gets secrets** from Secrets Manager (via VPC Endpoint)
3. **Injects environment variables:**
   ```
   ENVIRONMENT=dev
   PORT=8000
   DB_HOST=devsecops-platform-dev-postgres.xxx.rds.amazonaws.com
   DB_PORT=5432
   DB_NAME=appdb
   DB_USERNAME=dbadmin          ← From Secrets Manager
   DB_PASSWORD=aX9#kL2$mN...    ← From Secrets Manager
   SECRET_KEY=f8a3b2c1d4e5...   ← From Secrets Manager
   ```
4. **Starts container** with `uvicorn src.main:app --host 0.0.0.0 --port 8000`
5. **Registers with ALB** target group
6. **ALB health checks** `/health` endpoint

---

## Deployment Steps

### Prerequisites

Make sure you have Docker installed:
```bash
docker --version
```

### All-in-One Command

```bash
# Set variables
AWS_ACCOUNT_ID=501894534533
AWS_REGION=us-east-1
ECR_REPO=devsecops-platform-dev

# Login to ECR
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# Build, tag, and push
cd /Users/charithkapuluru/Desktop/Proj-3/app
docker build -t $ECR_REPO .
docker tag $ECR_REPO:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO:latest
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO:latest
```

### After Pushing

ECS will automatically:
1. Detect new image (or you can force update)
2. Pull the new image
3. Start a new container
4. Health check passes → Old container stops

To force ECS to update immediately:
```bash
aws ecs update-service --cluster devsecops-platform-dev --service devsecops-platform-dev --force-new-deployment
```

---

## Verify Deployment

### Check ECS Task Status

```bash
aws ecs describe-services --cluster devsecops-platform-dev --services devsecops-platform-dev --query 'services[0].{desired:desiredCount,running:runningCount,pending:pendingCount}'
```

Expected output when healthy:
```json
{
    "desired": 1,
    "running": 1,
    "pending": 0
}
```

### Test the Application

```bash
# Get ALB URL
ALB_URL="devsecops-platform-dev-alb-2136057228.us-east-1.elb.amazonaws.com"

# Test health endpoint
curl http://$ALB_URL/health

# Test root endpoint
curl http://$ALB_URL/
```

Expected response:
```json
{"status": "healthy"}
{"message": "DevSecOps Platform API", "version": "1.0.0"}
```

---

## Troubleshooting

### Task Keeps Failing?

Check CloudWatch Logs:
```bash
aws logs tail /ecs/devsecops-platform-dev --follow
```

Common issues:
- **Can't connect to database**: Check security groups, RDS endpoint
- **Can't get secrets**: Check IAM role permissions
- **Image not found**: Make sure you pushed to the correct ECR repo

### Health Check Failing?

Make sure:
1. App listens on port 8000
2. `/health` endpoint returns 200
3. App starts within 60 seconds (startPeriod)

---

## What's Next

After Phase 5, your application is **running**!

In **Phase 6: Monitoring**, we'll add:
- CloudWatch Alarms (get alerts when things break)
- Dashboard (visualize metrics)
- SNS notifications (email alerts)
