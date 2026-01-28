# Phase 3: Data Layer - Detailed Explanation

## Table of Contents
1. [Overview](#overview)
2. [What We're Building](#what-were-building)
3. [Concepts Explained](#concepts-explained)
4. [The Code Explained](#the-code-explained)
5. [Architecture Diagram](#architecture-diagram)
6. [Why These Specific Choices?](#why-these-specific-choices)
7. [Cost](#cost)

---

## Overview

**Phase 3** creates the data storage layer - where your application stores its data and secrets.

**What we create:**
- 2 Secrets (database password + app secret key)
- 1 RDS PostgreSQL database

**Estimated Cost:** $0-15/month (Free Tier eligible!)

---

## What We're Building

| Component | Real-World Analogy |
|-----------|-------------------|
| **Secrets Manager** | A secure vault for passwords |
| **RDS PostgreSQL** | A managed database (like hiring a DBA) |

---

## Concepts Explained

### 1. Why Not Put Passwords in Code?

**The wrong way (NEVER do this):**
```python
# app.py
DATABASE_PASSWORD = "MySecretPassword123!"  # ❌ TERRIBLE IDEA!
```

**Problems:**
- Password visible in Git history forever
- Anyone with code access sees the password
- Can't change password without redeploying code
- Same password might end up in dev, staging, prod

**The right way: Secrets Manager**
```python
# app.py
import boto3
client = boto3.client('secretsmanager')
secret = client.get_secret_value(SecretId='my-app/dev/db-credentials')
DATABASE_PASSWORD = json.loads(secret['SecretString'])['password']
```

**Benefits:**
- Password stored securely in AWS (encrypted with KMS)
- Access controlled by IAM (only your app can read it)
- Can rotate passwords without touching code
- Different passwords for dev/staging/prod

---

### 2. Secrets Manager

**What is it?**
A secure vault service where you store sensitive data:
- Database passwords
- API keys
- JWT secret keys
- Any sensitive configuration

```
┌─────────────────────────────────────────────────────────────────┐
│                      SECRETS MANAGER                            │
│                                                                 │
│   ┌─────────────────────────────────────────────────────────┐   │
│   │  Secret: "devsecops-platform/dev/db-credentials"        │   │
│   │                                                         │   │
│   │  {                                                      │   │
│   │    "username": "dbadmin",                               │   │
│   │    "password": "aX9#kL2$mN...(auto-generated)",         │   │
│   │    "dbname": "appdb"                                    │   │
│   │  }                                                      │   │
│   │                                                         │   │
│   │  🔐 Encrypted with KMS key                              │   │
│   └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│   ┌─────────────────────────────────────────────────────────┐   │
│   │  Secret: "devsecops-platform/dev/app-secret"            │   │
│   │                                                         │   │
│   │  {                                                      │   │
│   │    "secret_key": "f8a3b2c1d4e5...(64 chars)"            │   │
│   │  }                                                      │   │
│   │                                                         │   │
│   │  🔐 Encrypted with KMS key                              │   │
│   └─────────────────────────────────────────────────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

**How ECS gets the secrets:**

```
┌─────────────────┐         ┌─────────────────┐         ┌─────────────────┐
│   ECS Starting  │────────▶│  VPC Endpoint   │────────▶│ Secrets Manager │
│   Container     │         │  (Private)      │         │                 │
│                 │◀────────│                 │◀────────│  Returns secret │
│  Injects as     │         │                 │         │                 │
│  ENV variable   │         │                 │         │                 │
└─────────────────┘         └─────────────────┘         └─────────────────┘

Container now has:
  DB_USERNAME=dbadmin
  DB_PASSWORD=aX9#kL2$mN...
```

---

### 3. RDS (Relational Database Service)

**What is RDS?**
Instead of setting up a database yourself (installing PostgreSQL, managing backups, patching, etc.), AWS does it all for you.

**Without RDS (self-managed):**
```
You have to:
├── Install PostgreSQL on EC2
├── Configure security
├── Set up backups manually
├── Apply security patches
├── Monitor disk space
├── Handle failover yourself
├── Recover from crashes
└── Wake up at 3 AM when things break 😴
```

**With RDS (managed):**
```
AWS does:
├── ✓ Installation
├── ✓ Backups (automatic, daily)
├── ✓ Security patches (automatic)
├── ✓ Monitoring
├── ✓ Storage management
├── ✓ Failover (if Multi-AZ)
└── ✓ You sleep peacefully 😴
```

---

### 4. RDS Components We Create

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          RDS SETUP                                      │
│                                                                         │
│   ┌─────────────────────────────────────────────────────────────────┐   │
│   │  1. DB SUBNET GROUP                                             │   │
│   │                                                                 │   │
│   │     "Put the database in these subnets"                         │   │
│   │                                                                 │   │
│   │     ┌─────────────────┐    ┌─────────────────┐                  │   │
│   │     │ Data Subnet 1   │    │ Data Subnet 2   │                  │   │
│   │     │ us-east-1a      │    │ us-east-1b      │                  │   │
│   │     │ 10.0.21.0/24    │    │ 10.0.22.0/24    │                  │   │
│   │     └─────────────────┘    └─────────────────┘                  │   │
│   │                                                                 │   │
│   └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
│   ┌─────────────────────────────────────────────────────────────────┐   │
│   │  2. DB PARAMETER GROUP                                          │   │
│   │                                                                 │   │
│   │     "Configure PostgreSQL settings"                             │   │
│   │                                                                 │   │
│   │     - log_statement = "all" (log all queries)                   │   │
│   │     - log_min_duration_statement = 1000 (log slow queries)      │   │
│   │                                                                 │   │
│   └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
│   ┌─────────────────────────────────────────────────────────────────┐   │
│   │  3. DB INSTANCE                                                 │   │
│   │                                                                 │   │
│   │     The actual database!                                        │   │
│   │                                                                 │   │
│   │     - Engine: PostgreSQL 16.3                                   │   │
│   │     - Size: db.t3.micro (Free Tier!)                            │   │
│   │     - Storage: 20GB SSD (encrypted with KMS)                    │   │
│   │     - Backups: 7 days retention                                 │   │
│   │     - Security Group: Only accepts traffic from App             │   │
│   │                                                                 │   │
│   └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## The Code Explained

### Secrets Module (`modules/secrets/main.tf`)

```hcl
# Step 1: Generate a random 32-character password
resource "random_password" "db_password" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"  # Allowed special characters
}

# Step 2: Create a "vault" in Secrets Manager
resource "aws_secretsmanager_secret" "db_credentials" {
  name        = "${var.project_name}/${var.environment}/db-credentials"
  description = "Database credentials"
  kms_key_id  = var.kms_key_arn  # Encrypt with our KMS key
}

# Step 3: Put the password in the vault
resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id

  secret_string = jsonencode({
    username = var.db_username    # "dbadmin"
    password = random_password.db_password.result  # The generated password
    dbname   = var.db_name        # "appdb"
  })
}
```

**What happens:**
1. Terraform generates a random password (you never see it!)
2. Creates a secret "container" in AWS
3. Puts the password inside, encrypted with KMS

---

### RDS Module (`modules/rds/main.tf`)

```hcl
# Step 1: Tell RDS which subnets to use
resource "aws_db_subnet_group" "main" {
  name        = "${var.project_name}-${var.environment}-db-subnet"
  subnet_ids  = var.subnet_ids  # Data subnets from Phase 1
}

# Step 2: Configure PostgreSQL settings
resource "aws_db_parameter_group" "main" {
  name   = "${var.project_name}-${var.environment}-pg-params"
  family = "postgres16"

  parameter {
    name  = "log_statement"
    value = "all"  # Log all SQL queries (useful for debugging)
  }

  parameter {
    name  = "log_min_duration_statement"
    value = "1000"  # Log queries taking more than 1 second
  }
}

# Step 3: Create the actual database
resource "aws_db_instance" "main" {
  identifier = "${var.project_name}-${var.environment}-postgres"

  # What database engine
  engine         = "postgres"
  engine_version = "16.3"

  # Size (Free Tier!)
  instance_class    = var.instance_class     # db.t3.micro
  allocated_storage = var.allocated_storage  # 20 GB
  storage_type      = "gp3"                  # SSD storage

  # Encryption
  storage_encrypted = true
  kms_key_id        = var.kms_key_arn  # Our KMS key from Phase 2

  # Credentials
  db_name  = var.db_name      # "appdb"
  username = var.db_username  # "dbadmin"
  password = var.db_password  # From Secrets Manager!

  # Network (THIS IS KEY!)
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.security_group_id]  # RDS SG from Phase 2
  publicly_accessible    = false  # NO public access!
  multi_az               = false  # Single AZ (saves money)

  # Backups
  backup_retention_period = 7              # Keep 7 days of backups
  backup_window           = "03:00-04:00"  # Backup at 3 AM UTC

  # For dev environment
  deletion_protection = false  # Allow deletion
  skip_final_snapshot = true   # Don't require snapshot on delete
}
```

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                                   VPC                                       │
│                                                                             │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │                         PRIVATE SUBNET                              │   │
│   │                                                                     │   │
│   │   ┌─────────────────┐                                               │   │
│   │   │   ECS (future)  │                                               │   │
│   │   │                 │                                               │   │
│   │   │ 1. Get password │─────────┐                                     │   │
│   │   │    from Secrets │         │                                     │   │
│   │   │                 │         ▼                                     │   │
│   │   │                 │   ┌───────────────┐    ┌─────────────────┐    │   │
│   │   │                 │   │ VPC Endpoint  │───▶│ Secrets Manager │    │   │
│   │   │                 │   │ (Secrets)     │    │ (outside VPC)   │    │   │
│   │   │                 │   └───────────────┘    └─────────────────┘    │   │
│   │   │                 │                                               │   │
│   │   │ 2. Connect to   │                                               │   │
│   │   │    database     │─────────────────────────────┐                 │   │
│   │   │                 │                             │                 │   │
│   │   └─────────────────┘                             │                 │   │
│   │                                                   │                 │   │
│   └───────────────────────────────────────────────────┼─────────────────┘   │
│                                                       │                     │
│   ┌───────────────────────────────────────────────────┼─────────────────┐   │
│   │                         DATA SUBNET               │                 │   │
│   │                                                   ▼                 │   │
│   │                            ┌─────────────────────────────┐          │   │
│   │                            │      RDS PostgreSQL         │          │   │
│   │                            │                             │          │   │
│   │                            │  Endpoint: xxx.rds.amazon..│          │   │
│   │                            │  Port: 5432                 │          │   │
│   │                            │  Database: appdb            │          │   │
│   │                            │  User: dbadmin              │          │   │
│   │                            │                             │          │   │
│   │                            │  🔐 Encrypted with KMS      │          │   │
│   │                            │  📦 20GB SSD storage        │          │   │
│   │                            │  💾 7-day backups           │          │   │
│   │                            │                             │          │   │
│   │                            └─────────────────────────────┘          │   │
│   │                                                                     │   │
│   │   Security Group: Only allows port 5432 from App SG                 │   │
│   │                                                                     │   │
│   └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Data Flow: How App Connects to Database

```
STEP 1: ECS container starts
─────────────────────────────────────────────────────────────────────
ECS: "I need the database password"
     │
     ▼
ECS calls Secrets Manager (via VPC Endpoint)
     │
     ▼
Secrets Manager returns:
{
  "username": "dbadmin",
  "password": "aX9#kL2$mN...",
  "dbname": "appdb"
}
     │
     ▼
ECS injects these as environment variables into the container


STEP 2: Application connects to database
─────────────────────────────────────────────────────────────────────
App code:
  DATABASE_URL = f"postgresql://{DB_USERNAME}:{DB_PASSWORD}@{DB_HOST}:5432/{DB_NAME}"
  # postgresql://dbadmin:aX9#kL2$mN...@xxx.rds.amazonaws.com:5432/appdb

App connects to RDS endpoint on port 5432
     │
     ▼
Security Group check: "Is this from App SG?" ✓ YES
     │
     ▼
Connection established! App can now read/write data.
```

---

## Why These Specific Choices?

### 1. Why db.t3.micro?

| Instance | vCPU | RAM | Cost | Free Tier? |
|----------|------|-----|------|------------|
| **db.t3.micro** ✓ | 2 | 1GB | ~$15/mo | YES (750 hrs/mo) |
| db.t3.small | 2 | 2GB | ~$30/mo | No |
| db.t3.medium | 2 | 4GB | ~$60/mo | No |

For learning/dev, micro is plenty!

### 2. Why PostgreSQL (not MySQL)?

| Feature | PostgreSQL | MySQL |
|---------|------------|-------|
| JSON support | Excellent | Basic |
| Full-text search | Built-in | Limited |
| Advanced data types | Many | Fewer |
| Industry trend | Growing | Stable |
| Used by | Instagram, Spotify | Facebook, Twitter |

PostgreSQL is more "modern" and teaches you more.

### 3. Why Single-AZ (not Multi-AZ)?

| Mode | How It Works | Cost |
|------|--------------|------|
| **Single-AZ** ✓ | One database in one data center | $15/mo |
| Multi-AZ | Primary + standby in different data centers | $30/mo |

For dev environment, Single-AZ is fine. Use Multi-AZ in production.

### 4. Why 7-day backup retention?

- Shortest option that still gives you safety
- Can restore to any point in last 7 days
- Longer retention = more storage cost

### 5. Why skip_final_snapshot = true?

When you delete the database:
- `true` = Delete immediately (for dev - faster cleanup)
- `false` = Requires a final backup snapshot (for prod - safety)

---

## Security Summary

| Security Layer | Protection |
|----------------|------------|
| **Subnet** | Data subnet - no internet access |
| **Security Group** | Only App SG can connect on port 5432 |
| **Encryption at rest** | KMS encrypts all data on disk |
| **Encryption in transit** | SSL/TLS connection |
| **Password** | Auto-generated, stored in Secrets Manager |
| **Public access** | Disabled - `publicly_accessible = false` |

---

## Cost

| Resource | Monthly Cost |
|----------|--------------|
| RDS db.t3.micro | $0 (Free Tier) or ~$15 |
| 20GB gp3 storage | ~$2 |
| Secrets Manager (2 secrets) | ~$0.80 |
| **Total Phase 3** | **$0-18/month** |

**Free Tier Note:** If your AWS account is less than 12 months old, you get 750 hours/month of db.t3.micro FREE!

---

## What's Next

In **Phase 4: Compute Layer**, we'll create:
- **ECR** - Docker image repository
- **ALB** - Load balancer to receive traffic
- **ECS** - Run your containers

The ECS containers will:
1. Get database password from Secrets Manager (via VPC Endpoint)
2. Connect to RDS database (via Security Group rules)
3. Run your FastAPI application!
