# Phase 9: Cost Optimization

## Overview

Phase 9 implements **cost-saving measures** to keep your AWS bill low. We'll set up automatic scheduling to shut down resources when not needed and budget alerts to warn you before overspending.

**Estimated Cost:** ~$0/month (these resources are free or nearly free!)

---

## What We're Creating

### 1. Lambda Scheduler - Auto Start/Stop

**What is it?**
A Lambda function that automatically scales down your ECS service at night and scales it back up in the morning.

**Why?**
- ECS Fargate charges by the hour
- If you're not using the app at night/weekends, why pay for it?
- Can save 50-70% on compute costs!

**Analogy:**
Think of it like **automatic lights** in an office:
```
┌─────────────────────────────────────────────────────────┐
│                    OFFICE BUILDING                       │
│                                                          │
│   8:00 AM - Lights turn ON automatically                │
│             (Employees arrive, need lights)             │
│                                                          │
│   6:00 PM - Lights turn OFF automatically               │
│             (Everyone leaves, save electricity)         │
│                                                          │
│   Result: 60% electricity savings!                      │
└─────────────────────────────────────────────────────────┘

Same concept for your ECS tasks:

   8:00 AM - ECS scales UP (1 task)
             App is available for work

   6:00 PM - ECS scales DOWN (0 tasks)
             App sleeps, no charges

   Result: You only pay for 10 hours instead of 24!
```

**Our Schedule (UTC timezone):**
```
Scale UP:   8:00 AM EST (1:00 PM UTC) Mon-Fri
Scale DOWN: 6:00 PM EST (11:00 PM UTC) Mon-Fri
```

**How It Works:**
```
┌─────────────────┐         ┌─────────────────┐         ┌─────────────────┐
│  EventBridge    │         │     Lambda      │         │      ECS        │
│  (Scheduler)    │────────▶│   (Function)    │────────▶│   (Service)     │
└─────────────────┘         └─────────────────┘         └─────────────────┘
        │                           │                           │
   "It's 8 AM!"              "Scale ECS to              "Now running
                              1 task"                    1 container"
```

**The Lambda Code:**
```python
import boto3

def handler(event, context):
    ecs = boto3.client('ecs')

    # Get desired count from event (1 = up, 0 = down)
    desired_count = event.get('desired_count', 1)

    # Update ECS service
    ecs.update_service(
        cluster='devsecops-platform-dev',
        service='devsecops-platform-dev',
        desiredCount=desired_count
    )

    return f"Scaled to {desired_count} tasks"
```

---

### 2. AWS Budgets - Spending Alerts

**What is it?**
AWS Budgets monitors your spending and sends email alerts when you approach or exceed your budget.

**Why?**
- Avoid surprise bills
- Get warned BEFORE you overspend
- Track costs in real-time

**Analogy:**
Like a **bank account alert**:
```
┌─────────────────────────────────────────────────────────┐
│                   BANK ACCOUNT                           │
│                                                          │
│   Balance: $100                                         │
│                                                          │
│   Alert 1: "You've spent 50% ($50)"  ← Warning          │
│   Alert 2: "You've spent 80% ($80)"  ← Urgent           │
│   Alert 3: "You've exceeded $100!"   ← Over budget      │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

**Our Budget Alerts:**

| Budget | Limit | Alert at |
|--------|-------|----------|
| Project Budget | $50/month | 50%, 80%, 100% |
| Account Budget | $100/month | 50%, 80%, 100% |

**What Happens:**
```
Your spending: $0 ──────────────────────────────────────▶ $50
                   │           │           │           │
                   │           │           │           │
               $25 (50%)    $40 (80%)   $50 (100%)    │
                   │           │           │           │
                   ▼           ▼           ▼           │
               📧 Email    📧 Email    📧 Email       │
               "Warning"   "Urgent"    "Exceeded!"    │
```

---

### 3. EventBridge Rules - The Scheduler

**What is it?**
EventBridge is like a **cron job** in the cloud. It triggers actions on a schedule.

**Cron Expression Explained:**
```
cron(0 13 ? * MON-FRI *)
      │ │  │ │    │    │
      │ │  │ │    │    └── Year (any)
      │ │  │ │    └─────── Day of week (Monday-Friday)
      │ │  │ └──────────── Month (any)
      │ │  └────────────── Day of month (any)
      │ └───────────────── Hour (13 = 1 PM UTC = 8 AM EST)
      └─────────────────── Minute (0)

Translation: "At 1:00 PM UTC, Monday through Friday"
```

**Our Schedules:**
```
Scale UP:   cron(0 13 ? * MON-FRI *)  → 8 AM EST, weekdays
Scale DOWN: cron(0 23 ? * MON-FRI *)  → 6 PM EST, weekdays
```

---

## Cost Savings Calculation

**Without Scheduler (24/7 running):**
```
ECS Fargate (0.25 vCPU, 0.5 GB):
  - Cost per hour: ~$0.01
  - Hours per month: 24 × 30 = 720 hours
  - Monthly cost: $7.20

ALB (always on):
  - Monthly cost: ~$16

Total: ~$23/month
```

**With Scheduler (10 hours/day, weekdays only):**
```
ECS Fargate:
  - Hours per month: 10 × 22 = 220 hours
  - Monthly cost: $2.20

ALB (still always on):
  - Monthly cost: ~$16

Total: ~$18/month

SAVINGS: ~$5/month (22% reduction on compute!)
```

**Note:** ALB runs 24/7 regardless. To save more, you could stop ALB too, but then the app URL wouldn't respond at all during off-hours.

---

## Architecture After Phase 9

```
┌─────────────────────────────────────────────────────────────────────────┐
│                              AWS Account                                 │
│                                                                          │
│  ┌────────────────────────────────────────────────────────────────────┐ │
│  │                     COST OPTIMIZATION                               │ │
│  │                                                                     │ │
│  │   ┌─────────────┐    8 AM     ┌─────────────┐    Scale Up          │ │
│  │   │ EventBridge │────────────▶│   Lambda    │────────────▶ ECS=1   │ │
│  │   │  (Schedule) │             │ (Scheduler) │                      │ │
│  │   └─────────────┘    6 PM     └─────────────┘    Scale Down        │ │
│  │         │        ────────────────────────────────────────▶ ECS=0   │ │
│  │         │                                                          │ │
│  └─────────┼──────────────────────────────────────────────────────────┘ │
│            │                                                             │
│  ┌─────────┼──────────────────────────────────────────────────────────┐ │
│  │         │              BUDGET MONITORING                            │ │
│  │         ▼                                                           │ │
│  │   ┌─────────────┐         ┌─────────────┐                          │ │
│  │   │ AWS Budgets │────────▶│    SNS      │────────▶ 📧 Email        │ │
│  │   │  ($50 limit)│ Alert!  │   Topic     │         "Budget warning" │ │
│  │   └─────────────┘         └─────────────┘                          │ │
│  │                                                                     │ │
│  └─────────────────────────────────────────────────────────────────────┘ │
│                                                                          │
│  ┌─────────────────────────────────────────────────────────────────────┐ │
│  │                        YOUR APPLICATION                              │ │
│  │      [ALB] ──▶ [ECS Fargate] ──▶ [RDS PostgreSQL]                  │ │
│  │                    │                                                │ │
│  │              (scales 0↔1)                                           │ │
│  └─────────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Terraform Code Highlights

### Lambda Function
```hcl
resource "aws_lambda_function" "scheduler" {
  function_name = "devsecops-platform-dev-scheduler"
  runtime       = "python3.11"
  handler       = "index.handler"
  timeout       = 30

  environment {
    variables = {
      ECS_CLUSTER = "devsecops-platform-dev"
      ECS_SERVICE = "devsecops-platform-dev"
    }
  }
}
```

### EventBridge Schedule
```hcl
resource "aws_cloudwatch_event_rule" "scale_up" {
  name                = "scale-up-schedule"
  schedule_expression = "cron(0 13 ? * MON-FRI *)"  # 8 AM EST
}

resource "aws_cloudwatch_event_rule" "scale_down" {
  name                = "scale-down-schedule"
  schedule_expression = "cron(0 23 ? * MON-FRI *)"  # 6 PM EST
}
```

### AWS Budget
```hcl
resource "aws_budgets_budget" "project" {
  name         = "devsecops-platform-monthly"
  budget_type  = "COST"
  limit_amount = "50"
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  notification {
    threshold         = 80  # Alert at 80%
    notification_type = "ACTUAL"
    subscriber_email_addresses = ["your-email@example.com"]
  }
}
```

---

## After Deployment - What to Check

### 1. View Lambda Function
```
AWS Console → Lambda → devsecops-platform-dev-scheduler
```

### 2. View EventBridge Rules
```
AWS Console → EventBridge → Rules
- devsecops-platform-dev-scale-up
- devsecops-platform-dev-scale-down
```

### 3. View Budgets
```
AWS Console → Billing → Budgets
- devsecops-platform-monthly
- aws-account-monthly
```

### 4. Test Scheduler Manually
You can invoke the Lambda manually to test:
```bash
# Scale down
aws lambda invoke --function-name devsecops-platform-dev-scheduler \
  --payload '{"desired_count": 0}' response.json

# Scale up
aws lambda invoke --function-name devsecops-platform-dev-scheduler \
  --payload '{"desired_count": 1}' response.json
```

---

## Cost Summary

| Resource | Cost |
|----------|------|
| Lambda Function | FREE (1M requests/month free) |
| EventBridge | FREE (built-in scheduler) |
| AWS Budgets | FREE (first 2 budgets) |
| **Total** | **$0/month** |

**Potential Savings:** $5-10/month on ECS compute!

---

## Summary

| Component | Purpose |
|-----------|---------|
| **Lambda Scheduler** | Automatically scale ECS up/down |
| **EventBridge Rules** | Trigger Lambda on schedule |
| **AWS Budgets** | Alert when spending exceeds limits |

**Think of it as:**
- Lambda Scheduler = Automatic light switch
- EventBridge = Timer that flips the switch
- AWS Budgets = Bank balance alerts
