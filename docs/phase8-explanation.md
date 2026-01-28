# Phase 8: CI/CD Pipeline (GitHub Actions)

## Overview

Phase 8 sets up **Continuous Integration / Continuous Deployment (CI/CD)** using GitHub Actions. This automates the process of testing your code and deploying it to AWS whenever you push changes.

**Cost:** FREE (GitHub Actions is free for public repos, 2000 min/month for private)

**Note:** This phase has NO Terraform resources - it's all GitHub configuration.

---

## What is CI/CD?

**CI (Continuous Integration):**
- Automatically test your code when you push
- Catch bugs before they reach production
- Ensure code quality with automated checks

**CD (Continuous Deployment):**
- Automatically deploy code after tests pass
- No manual deployment steps
- Consistent, repeatable deployments

**Analogy:**
Think of it like a **factory assembly line**:
```
Code Push → Quality Check → Testing → Packaging → Shipping to Production
   │              │            │           │              │
   │              │            │           │              └─ Deploy to ECS
   │              │            │           └─ Build Docker image
   │              │            └─ Run automated tests
   │              └─ Lint code, check formatting
   └─ Developer pushes code to GitHub
```

---

## How It Works

```
┌─────────────────────────────────────────────────────────────────────┐
│                        GITHUB ACTIONS                               │
│                                                                     │
│  1. Developer pushes code                                           │
│         │                                                           │
│         ▼                                                           │
│  2. GitHub Actions triggered                                        │
│         │                                                           │
│         ▼                                                           │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                    CI PIPELINE                               │   │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐    │   │
│  │  │  Lint    │→ │  Test    │→ │  Build   │→ │  Scan    │    │   │
│  │  │  Code    │  │  Code    │  │  Docker  │  │  Image   │    │   │
│  │  └──────────┘  └──────────┘  └──────────┘  └──────────┘    │   │
│  └─────────────────────────────────────────────────────────────┘   │
│         │                                                           │
│         ▼ (if all pass)                                            │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                    CD PIPELINE                               │   │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐                  │   │
│  │  │  Push to │→ │  Update  │→ │  Deploy  │                  │   │
│  │  │   ECR    │  │  Task    │  │  to ECS  │                  │   │
│  │  └──────────┘  └──────────┘  └──────────┘                  │   │
│  └─────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
                    ┌─────────────────┐
                    │   AWS ECS       │
                    │ (Your app is    │
                    │  now updated!)  │
                    └─────────────────┘
```

---

## OIDC Authentication (Already Set Up!)

In Phase 2, we created an **OIDC provider** and **IAM role** for GitHub Actions. This allows GitHub to securely authenticate with AWS without storing long-lived credentials.

**How OIDC Works:**
```
┌─────────────────┐         ┌─────────────────┐         ┌─────────────────┐
│  GitHub Action  │         │   AWS IAM       │         │   AWS Services  │
│                 │         │   OIDC Provider │         │   (ECR, ECS)    │
│  1. "I am repo  │────────▶│                 │         │                 │
│     X running   │         │  2. Verify      │         │                 │
│     workflow Y" │         │     identity    │         │                 │
│                 │◀────────│                 │         │                 │
│  3. Receive     │         │  4. Issue       │         │                 │
│     temp creds  │─────────┼────────────────▶│  5. Access granted      │
└─────────────────┘         └─────────────────┘         └─────────────────┘
```

**Benefits:**
- No AWS access keys stored in GitHub
- Temporary credentials (expire in 1 hour)
- Only your specific repo can assume the role

**Your Role ARN:**
```
arn:aws:iam::501894534533:role/devsecops-platform-dev-github-actions
```

---

## GitHub Actions Workflow Files

Create these files in your repository:

### 1. CI Workflow (`.github/workflows/ci.yml`)

```yaml
name: CI Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

env:
  PYTHON_VERSION: "3.12"

jobs:
  lint:
    name: Lint Code
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: ${{ env.PYTHON_VERSION }}

      - name: Install dependencies
        run: |
          pip install ruff

      - name: Run Ruff linter
        run: ruff check app/src/

  test:
    name: Run Tests
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: ${{ env.PYTHON_VERSION }}

      - name: Install dependencies
        run: |
          pip install -r app/requirements.txt
          pip install pytest pytest-asyncio

      - name: Run tests
        run: |
          cd app
          python -m pytest src/tests/ -v
        env:
          DATABASE_URL: "sqlite+aiosqlite:///./test.db"
          SECRET_KEY: "test-secret-key"

  build:
    name: Build Docker Image
    runs-on: ubuntu-latest
    needs: [lint, test]  # Only run if lint and test pass
    steps:
      - uses: actions/checkout@v4

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Build Docker image
        uses: docker/build-push-action@v5
        with:
          context: ./app
          push: false
          tags: devsecops-platform:${{ github.sha }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
```

### 2. CD Workflow (`.github/workflows/deploy.yml`)

```yaml
name: Deploy to AWS

on:
  push:
    branches: [main]  # Only deploy from main branch
  workflow_dispatch:   # Allow manual trigger

env:
  AWS_REGION: us-east-1
  ECR_REPOSITORY: devsecops-platform-dev
  ECS_CLUSTER: devsecops-platform-dev
  ECS_SERVICE: devsecops-platform-dev

permissions:
  id-token: write   # Required for OIDC
  contents: read

jobs:
  deploy:
    name: Deploy to ECS
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      # Authenticate with AWS using OIDC
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::501894534533:role/devsecops-platform-dev-github-actions
          aws-region: ${{ env.AWS_REGION }}

      # Login to ECR
      - name: Login to Amazon ECR
        id: login-ecr
        uses: aws-actions/amazon-ecr-login@v2

      # Build and push Docker image
      - name: Build, tag, and push image to ECR
        id: build-image
        env:
          ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
          IMAGE_TAG: ${{ github.sha }}
        run: |
          cd app
          docker build --platform linux/amd64 -t $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG .
          docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
          echo "image=$ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG" >> $GITHUB_OUTPUT

      # Update ECS service
      - name: Deploy to ECS
        run: |
          aws ecs update-service \
            --cluster $ECS_CLUSTER \
            --service $ECS_SERVICE \
            --force-new-deployment

      # Wait for deployment to complete
      - name: Wait for deployment
        run: |
          aws ecs wait services-stable \
            --cluster $ECS_CLUSTER \
            --services $ECS_SERVICE

      - name: Deployment complete
        run: |
          echo "✅ Deployment successful!"
          echo "🌐 App URL: http://devsecops-platform-dev-alb-2136057228.us-east-1.elb.amazonaws.com"
```

---

## Workflow Explanation

### CI Pipeline Steps:

| Step | What It Does | Why It Matters |
|------|--------------|----------------|
| **Lint** | Checks code style/formatting | Catches style issues early |
| **Test** | Runs automated tests | Ensures code works correctly |
| **Build** | Builds Docker image | Verifies image can be built |

### CD Pipeline Steps:

| Step | What It Does | Why It Matters |
|------|--------------|----------------|
| **Configure AWS** | Authenticate via OIDC | Secure, no stored credentials |
| **Login ECR** | Get Docker registry token | Required to push images |
| **Build & Push** | Build image, push to ECR | New version ready for deploy |
| **Deploy** | Update ECS service | Triggers rolling deployment |
| **Wait** | Wait for deployment | Ensures deployment succeeded |

---

## Setting Up in Your Repository

### Step 1: Create Workflow Directory
```bash
mkdir -p .github/workflows
```

### Step 2: Create CI Workflow
```bash
# Create .github/workflows/ci.yml with content above
```

### Step 3: Create Deploy Workflow
```bash
# Create .github/workflows/deploy.yml with content above
```

### Step 4: Update GitHub Repo Settings

**Important:** You need to update your `terraform.tfvars` with your actual GitHub username and repo:

```hcl
# In terraform/environments/dev/terraform.tfvars
github_org  = "your-actual-github-username"
github_repo = "your-actual-repo-name"
```

Then run `terraform apply` to update the IAM role trust policy.

### Step 5: Push to GitHub
```bash
git add .github/workflows/
git commit -m "Add CI/CD workflows"
git push origin main
```

---

## Workflow Triggers

| Event | CI Pipeline | Deploy Pipeline |
|-------|-------------|-----------------|
| Push to `main` | ✅ Runs | ✅ Runs |
| Push to `develop` | ✅ Runs | ❌ No |
| Pull Request to `main` | ✅ Runs | ❌ No |
| Manual trigger | ❌ No | ✅ Runs |

---

## Viewing Workflow Runs

1. Go to your GitHub repository
2. Click **Actions** tab
3. See all workflow runs with status

```
┌─────────────────────────────────────────────────────────────────┐
│  Actions                                                        │
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │ ✅ CI Pipeline - main - 2m ago                            │ │
│  │    Lint ✅ | Test ✅ | Build ✅                           │ │
│  └───────────────────────────────────────────────────────────┘ │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │ ✅ Deploy to AWS - main - 5m ago                          │ │
│  │    Deploy ✅                                               │ │
│  └───────────────────────────────────────────────────────────┘ │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │ ❌ CI Pipeline - feature/new-api - 1h ago                 │ │
│  │    Lint ✅ | Test ❌ | Build ⏭️                           │ │
│  └───────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

---

## Security Best Practices

| Practice | How We Implement It |
|----------|---------------------|
| **No stored credentials** | OIDC for AWS authentication |
| **Principle of least privilege** | IAM role only has needed permissions |
| **Branch protection** | Only deploy from `main` branch |
| **Test before deploy** | CI must pass before CD runs |
| **Audit trail** | GitHub Actions logs all runs |

---

## Troubleshooting

### "Error: Could not assume role"
- Check that `github_org` and `github_repo` in tfvars match your actual repo
- Run `terraform apply` after updating

### "Error: Access Denied to ECR"
- Verify the IAM role has ECR permissions
- Check the role trust policy includes your repo

### "Deployment timeout"
- Check ECS task logs in CloudWatch
- Verify the container starts successfully
- Check health check endpoint is responding

---

## Summary

| Component | Purpose |
|-----------|---------|
| **CI Workflow** | Lint, test, build on every push |
| **CD Workflow** | Deploy to ECS on main branch |
| **OIDC** | Secure AWS authentication |
| **ECR** | Docker image registry |
| **ECS** | Container orchestration |

**The Complete Flow:**
```
Code Push → Lint → Test → Build → Push to ECR → Deploy to ECS → Live!
```

---

## Next Steps

1. Create `.github/workflows/` directory in your repo
2. Add the workflow files
3. Update `github_org` and `github_repo` in terraform.tfvars
4. Run `terraform apply`
5. Push to GitHub and watch the magic happen!
