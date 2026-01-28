# Phase 7: Security Services

## Overview

Phase 7 adds **security monitoring** to your infrastructure. These services act like security cameras and auditors for your AWS account - they record everything that happens and alert you to potential security issues.

**Estimated Cost:** ~$1/month (mostly free!)

---

## What We're Creating

### 1. CloudTrail - The Security Camera

**What is it?**
CloudTrail records **every API call** made in your AWS account. Think of it as a security camera that records who did what, when, and from where.

**Analogy:**
Imagine a **building security system**:
- Every time someone enters a room, swipes a card, or opens a door → it's logged
- If something goes wrong, you can review the footage
- You can see: Who? What? When? Where?

```
CloudTrail = Security Camera for AWS

Records:
- Who made the API call (user/role)
- What action was taken (CreateBucket, DeleteInstance, etc.)
- When it happened (timestamp)
- Where (source IP address)
- Was it successful or denied?
```

**What Gets Logged:**

| Action | Example Log Entry |
|--------|-------------------|
| Create EC2 | "User john created instance i-123" |
| Delete S3 object | "Role app-role deleted file.txt from bucket" |
| Login attempt | "User alice logged in from IP 1.2.3.4" |
| Permission denied | "User bob tried to access secrets (DENIED)" |

**Our Configuration:**
```hcl
resource "aws_cloudtrail" "main" {
  name                          = "devsecops-platform-dev"
  s3_bucket_name                = aws_s3_bucket.cloudtrail.id
  include_global_service_events = true   # Include IAM, CloudFront, etc.
  is_multi_region_trail         = false  # Single region (cost saving)
  enable_log_file_validation    = true   # Detect if logs are tampered
  kms_key_id                    = var.kms_key_arn  # Encrypt logs

  event_selector {
    read_write_type           = "All"    # Log both reads and writes
    include_management_events = true      # API calls (FREE!)
  }
}
```

**Key Settings Explained:**

| Setting | What It Does |
|---------|--------------|
| `enable_log_file_validation` | Creates hash of each log file - detects tampering |
| `is_multi_region_trail = false` | Only logs this region (saves money) |
| `include_management_events = true` | Logs API calls (free tier) |
| `kms_key_id` | Encrypts logs with our KMS key |

---

### 2. CloudTrail S3 Bucket - The Storage Vault

**What is it?**
A secure S3 bucket where all CloudTrail logs are stored.

**Security Features:**
```
┌─────────────────────────────────────────────────────────┐
│                  CloudTrail S3 Bucket                   │
│                                                         │
│  [✓] Encryption (KMS)     - Logs encrypted at rest     │
│  [✓] Versioning           - Can't silently delete logs │
│  [✓] Block Public Access  - No internet access         │
│  [✓] Lifecycle Rules      - Auto-delete after 90 days  │
│  [✓] Bucket Policy        - Only CloudTrail can write  │
└─────────────────────────────────────────────────────────┘
```

**Lifecycle Policy:**
```hcl
rule {
  id     = "expire-old-logs"
  status = "Enabled"

  expiration {
    days = 90  # Delete logs after 90 days (saves storage cost)
  }

  noncurrent_version_expiration {
    noncurrent_days = 30  # Delete old versions after 30 days
  }
}
```

**Why 90 days?**
- Most security investigations happen within days/weeks
- Keeping logs forever = expensive
- 90 days is a good balance for dev environment
- Production might keep logs longer (1 year+)

---

### 3. IAM Access Analyzer - The Security Auditor

**What is it?**
Access Analyzer automatically scans your resources and alerts you if anything is accessible from **outside your AWS account**.

**Analogy:**
Imagine hiring a **security auditor** who:
- Walks through your building every day
- Checks every door, window, and lock
- Reports: "Hey, this back door is unlocked!"
- Specifically looks for ways outsiders could get in

```
Access Analyzer = Continuous Security Audit

Scans:
- S3 buckets      → "Is this bucket public?"
- IAM roles       → "Can external accounts assume this?"
- KMS keys        → "Can outsiders use this key?"
- Lambda          → "Is this function publicly callable?"
- SQS queues      → "Can external accounts send messages?"
- Secrets Manager → "Can outsiders read these secrets?"
```

**Example Finding:**
```
FINDING: External Access Detected!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Resource: arn:aws:s3:::my-bucket
Issue: Bucket policy allows access from ANY AWS account
Risk: HIGH - Data could be accessed by anyone

Recommendation: Update bucket policy to restrict access
```

**Our Configuration:**
```hcl
resource "aws_accessanalyzer_analyzer" "main" {
  analyzer_name = "devsecops-platform-dev-analyzer"
  type          = "ACCOUNT"  # Analyze resources in this account
}
```

**Type Options:**
- `ACCOUNT` - Analyzes resources in your account (what we use)
- `ORGANIZATION` - Analyzes across all accounts in AWS Organization

---

## How CloudTrail Works - Complete Flow

```
    User/Service makes API call
              │
              ▼
    ┌─────────────────┐
    │   AWS API       │
    │   (EC2, S3,     │
    │    IAM, etc.)   │
    └────────┬────────┘
              │
              │ Every API call is logged
              ▼
    ┌─────────────────┐
    │   CloudTrail    │
    │   (Records      │
    │    everything)  │
    └────────┬────────┘
              │
              │ Logs delivered every ~5 minutes
              ▼
    ┌─────────────────┐
    │   S3 Bucket     │
    │   (Encrypted    │
    │    storage)     │
    └────────┬────────┘
              │
              │ You can query logs
              ▼
    ┌─────────────────┐
    │   CloudWatch    │
    │   Logs Insights │
    │   or Athena     │
    └─────────────────┘
```

---

## Example CloudTrail Log Entry

When someone creates an EC2 instance:

```json
{
  "eventTime": "2026-01-27T10:30:00Z",
  "eventSource": "ec2.amazonaws.com",
  "eventName": "RunInstances",
  "awsRegion": "us-east-1",
  "sourceIPAddress": "203.0.113.50",
  "userIdentity": {
    "type": "IAMUser",
    "userName": "john.doe",
    "arn": "arn:aws:iam::123456789:user/john.doe"
  },
  "requestParameters": {
    "instanceType": "t3.micro",
    "imageId": "ami-12345678"
  },
  "responseElements": {
    "instancesSet": {
      "instanceId": "i-0abc123def456"
    }
  }
}
```

**What this tells us:**
- **Who:** john.doe
- **What:** Created an EC2 instance (RunInstances)
- **When:** 2026-01-27 at 10:30 AM
- **Where:** From IP 203.0.113.50
- **Details:** t3.micro instance using ami-12345678
- **Result:** Instance i-0abc123def456 was created

---

## How Access Analyzer Works

```
    ┌─────────────────────────────────────────────────┐
    │              Your AWS Account                    │
    │                                                  │
    │   ┌──────────┐  ┌──────────┐  ┌──────────┐     │
    │   │ S3       │  │ IAM      │  │ KMS      │     │
    │   │ Buckets  │  │ Roles    │  │ Keys     │     │
    │   └────┬─────┘  └────┬─────┘  └────┬─────┘     │
    │        │             │             │            │
    │        └─────────────┼─────────────┘            │
    │                      │                          │
    │                      ▼                          │
    │           ┌──────────────────┐                  │
    │           │ Access Analyzer  │                  │
    │           │ (Scans policies) │                  │
    │           └────────┬─────────┘                  │
    │                    │                            │
    └────────────────────┼────────────────────────────┘
                         │
                         │ Checks: "Can anyone OUTSIDE
                         │          this account access
                         │          these resources?"
                         ▼
              ┌─────────────────────┐
              │     FINDINGS        │
              │                     │
              │  • Public S3 bucket │
              │  • External role    │
              │    trust            │
              └─────────────────────┘
```

---

## Security Best Practices Implemented

| Practice | How We Implement It |
|----------|---------------------|
| **Audit Trail** | CloudTrail logs all API calls |
| **Log Integrity** | Log file validation detects tampering |
| **Encryption at Rest** | Logs encrypted with KMS |
| **No Public Access** | S3 bucket blocks all public access |
| **Log Retention** | Auto-delete after 90 days |
| **Continuous Monitoring** | Access Analyzer runs continuously |
| **External Access Detection** | Alerts on public/external resources |

---

## Cost Breakdown

| Service | Cost |
|---------|------|
| **CloudTrail** | FREE (management events) |
| **S3 Storage** | ~$0.50-1/month (logs) |
| **Access Analyzer** | FREE |
| **KMS** | Already included in Phase 2 |
| **Total** | **~$1/month** |

**What Would Cost Extra (not included):**
- Data events (S3 object-level logging): $0.10 per 100,000 events
- Multi-region trail: Same cost, but duplicated
- Long-term storage: Keeping logs for years

---

## After Deployment - What to Check

### 1. View CloudTrail
```
AWS Console → CloudTrail → Trails → devsecops-platform-dev
```

### 2. View Recent Events
```
AWS Console → CloudTrail → Event history
```
You'll see all API calls in the last 90 days!

### 3. Check Access Analyzer Findings
```
AWS Console → IAM → Access Analyzer → Findings
```
If empty = no external access detected (good!)

### 4. View S3 Logs Bucket
```
AWS Console → S3 → devsecops-platform-dev-cloudtrail-[account-id]
```

---

## Architecture After Phase 7

```
┌──────────────────────────────────────────────────────────────────────┐
│                           AWS Account                                 │
│                                                                       │
│  ┌─────────────────────────────────────────────────────────────────┐ │
│  │                         Your VPC                                 │ │
│  │   [ALB] → [ECS] → [RDS]                                        │ │
│  │     │       │       │                                           │ │
│  │     └───────┼───────┘                                           │ │
│  │             │                                                    │ │
│  └─────────────┼────────────────────────────────────────────────────┘ │
│                │                                                       │
│                │   Every API call                                      │
│                ▼                                                       │
│  ┌─────────────────────┐    ┌─────────────────────────────────────┐  │
│  │    CloudTrail       │    │       Access Analyzer               │  │
│  │  (Records all       │    │     (Scans for external            │  │
│  │   API activity)     │    │      access risks)                 │  │
│  └──────────┬──────────┘    └─────────────────────────────────────┘  │
│             │                                                         │
│             ▼                                                         │
│  ┌─────────────────────┐                                             │
│  │    S3 Bucket        │                                             │
│  │  (Encrypted logs)   │                                             │
│  │  - Versioned        │                                             │
│  │  - 90-day retention │                                             │
│  └─────────────────────┘                                             │
│                                                                       │
│  ┌─────────────────────┐                                             │
│  │  CloudWatch         │  (from Phase 6)                             │
│  │  - Dashboard        │                                             │
│  │  - Alarms → Email   │                                             │
│  └─────────────────────┘                                             │
└──────────────────────────────────────────────────────────────────────┘
```

---

## Use Cases

### Incident Investigation
```
"Someone deleted our production database!"

1. Open CloudTrail Event History
2. Filter: eventName = "DeleteDBInstance"
3. Find: Who did it, when, from where
4. Result: "User X deleted DB at 3:42 PM from IP Y"
```

### Security Audit
```
"Are any of our resources publicly accessible?"

1. Open IAM Access Analyzer
2. Check Findings
3. If findings exist → resources have external access
4. Remediate: Update policies to restrict access
```

### Compliance
```
"Prove that only authorized users accessed sensitive data"

1. Query CloudTrail logs
2. Filter by resource (RDS, Secrets Manager)
3. Export access log report
4. Result: Audit-ready evidence
```

---

## Summary

| Service | Purpose | Cost |
|---------|---------|------|
| **CloudTrail** | Records all API activity | FREE |
| **S3 Bucket** | Stores logs securely | ~$1/mo |
| **Access Analyzer** | Detects external access risks | FREE |

**Think of it as:**
- CloudTrail = Security camera recordings
- S3 Bucket = Video storage vault
- Access Analyzer = Security guard checking for unlocked doors
