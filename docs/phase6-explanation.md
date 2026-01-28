# Phase 6: Monitoring & Alerting

## Overview

Phase 6 sets up **monitoring infrastructure** to watch your application and alert you when something goes wrong. Think of it as installing security cameras and alarm systems for your application.

**Estimated Cost:** ~$2-5/month

---

## What We're Creating

### 1. SNS Topic (Simple Notification Service)

**What is it?**
SNS is like a **broadcast system**. When something goes wrong, it sends notifications to everyone who subscribed.

**Analogy:**
Think of it like a **fire alarm system** in a building:
- When smoke is detected (alarm triggers)
- The fire alarm (SNS) broadcasts the alert
- Everyone subscribed (email recipients) gets notified

```
[CloudWatch Alarm Triggered]
           |
           v
     [SNS Topic]
           |
    +------+------+
    |      |      |
  Email  Slack   SMS
```

**Our Configuration:**
```hcl
resource "aws_sns_topic" "alerts" {
  name = "devsecops-platform-dev-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = "your-email@example.com"
}
```

---

### 2. CloudWatch Alarms

**What are they?**
Alarms watch specific **metrics** and trigger when something exceeds a threshold.

**Analogy:**
Like a **temperature gauge** in your car:
- It constantly monitors the engine temperature
- If it goes above a threshold (overheating) → alarm triggers
- You get notified to take action

#### Alarm 1: ALB 5xx Errors

```
What it monitors: HTTP 500 errors (server errors)
Threshold: More than 10 errors in 5 minutes
Why it matters: 500 errors mean your app is crashing or having issues
```

```hcl
resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "devsecops-platform-dev-alb-5xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2        # Check for 2 consecutive periods
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 300      # 5 minutes
  threshold           = 10       # More than 10 errors

  alarm_actions = [aws_sns_topic.alerts.arn]  # Send email when triggered
}
```

**Flow:**
```
User → ALB → App (crashes) → Returns 500 Error
                   ↓
        CloudWatch collects metric
                   ↓
        10+ errors in 5 minutes?
                   ↓
            Alarm triggers
                   ↓
            SNS sends email
```

#### Alarm 2: ECS Running Tasks

```
What it monitors: Number of running containers
Threshold: Less than 1 task running
Why it matters: If no tasks running, your app is DOWN
```

```hcl
resource "aws_cloudwatch_metric_alarm" "ecs_running_tasks" {
  alarm_name          = "devsecops-platform-dev-ecs-running-tasks"
  comparison_operator = "LessThanThreshold"
  threshold           = 1        # Less than 1 = no tasks = app is down
  treat_missing_data  = "breaching"  # Missing data = assume it's bad

  dimensions = {
    ClusterName = "devsecops-platform-dev"
    ServiceName = "devsecops-platform-dev"
  }
}
```

**Why "treat_missing_data = breaching"?**
- If CloudWatch can't get data, something is seriously wrong
- We assume the worst and trigger the alarm

#### Alarm 3: RDS CPU Utilization

```
What it monitors: Database CPU usage
Threshold: Above 80% for 15 minutes (3 x 5-minute periods)
Why it matters: High CPU = database overloaded = slow queries
```

```hcl
resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "devsecops-platform-dev-rds-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3        # 3 consecutive checks
  period              = 300      # 5 minutes each
  threshold           = 80       # 80% CPU

  dimensions = {
    DBInstanceIdentifier = "devsecops-platform-dev-postgres"
  }
}
```

---

### 3. CloudWatch Dashboard

**What is it?**
A **visual dashboard** that shows all your metrics in one place.

**Analogy:**
Like the **dashboard in your car**:
- Shows speed, fuel, temperature, etc.
- One glance tells you the health of your vehicle
- You can spot problems before they become serious

**Our Dashboard Widgets:**

```
+------------------------+------------------------+
|   ALB Request Count    |   ALB Response Time    |
|   (How many requests)  |   (How fast)           |
+------------------------+------------------------+
|   ECS CPU Utilization  |   ECS Memory Usage     |
|   (Container health)   |   (Container memory)   |
+------------------------+------------------------+
|   RDS CPU Utilization  |   RDS Connections      |
|   (Database health)    |   (Active connections) |
+------------------------+------------------------+
```

**Code Snippet:**
```hcl
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "devsecops-platform-dev"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          title   = "ALB Request Count"
          metrics = [["AWS/ApplicationELB", "RequestCount", ...]]
        }
      },
      # ... more widgets
    ]
  })
}
```

---

## How Monitoring Works - Complete Flow

```
                     YOUR APPLICATION
                           |
    +----------------------+----------------------+
    |                      |                      |
    v                      v                      v
   ALB                   ECS                    RDS
(Load Balancer)      (Containers)           (Database)
    |                      |                      |
    |    Metrics flow to CloudWatch continuously  |
    +----------------------+----------------------+
                           |
                           v
                    +-------------+
                    | CloudWatch  |
                    | (Collects   |
                    |  Metrics)   |
                    +-------------+
                           |
           +---------------+---------------+
           |               |               |
           v               v               v
      [Alarm 1]       [Alarm 2]       [Alarm 3]
      ALB 5xx         ECS Tasks       RDS CPU
           |               |               |
           |  If threshold exceeded        |
           +---------------+---------------+
                           |
                           v
                    +-------------+
                    | SNS Topic   |
                    | (Broadcast) |
                    +-------------+
                           |
                           v
                    +-------------+
                    |   EMAIL     |
                    | (You get    |
                    |  notified)  |
                    +-------------+
```

---

## Key Metrics Explained

| Metric | What It Measures | Normal Range | Concern Level |
|--------|------------------|--------------|---------------|
| **RequestCount** | Total HTTP requests to ALB | Varies | Sudden drops = potential issue |
| **ResponseTime** | How fast app responds | < 500ms | > 1s = investigate |
| **5xx Errors** | Server errors | 0 | Any = investigate |
| **CPUUtilization** | CPU usage % | < 70% | > 80% = scale up |
| **MemoryUtilization** | Memory usage % | < 80% | > 90% = increase memory |
| **DatabaseConnections** | Active DB connections | < 80% of max | Near max = increase limit |

---

## Alarm States

CloudWatch alarms have 3 states:

```
1. OK (Green)
   └── Everything is fine, metric is within threshold

2. ALARM (Red)
   └── Metric exceeded threshold, action taken (email sent)

3. INSUFFICIENT_DATA (Gray)
   └── Not enough data to determine state
```

**State Transitions:**
```
    +--------+         Metric exceeds threshold          +--------+
    |   OK   | ----------------------------------------> | ALARM  |
    +--------+                                           +--------+
         ^                                                    |
         |            Metric returns to normal                |
         +----------------------------------------------------+
```

---

## What Happens When An Alarm Triggers?

**Example: ECS Task Crash**

```
1. [16:00:00] ECS Task crashes

2. [16:00:30] CloudWatch detects RunningTaskCount = 0

3. [16:05:00] First evaluation period ends
   - RunningTaskCount still = 0

4. [16:10:00] Second evaluation period ends (evaluation_periods = 2)
   - RunningTaskCount still = 0
   - Alarm state changes: OK → ALARM

5. [16:10:01] SNS sends email notification
   - Subject: "ALARM: devsecops-platform-dev-ecs-running-tasks"
   - Body: "Running tasks below threshold (0 < 1)"

6. [16:10:05] You receive email, investigate issue

7. [16:15:00] ECS auto-recovers, starts new task

8. [16:20:00] RunningTaskCount = 1
   - Alarm state changes: ALARM → OK

9. [16:20:01] SNS sends "OK" notification
   - You know the issue is resolved
```

---

## Cost Breakdown

| Resource | Cost |
|----------|------|
| SNS Topic | Free (first 1M requests) |
| SNS Email | Free |
| CloudWatch Alarms | $0.10/alarm/month × 3 = ~$0.30 |
| CloudWatch Dashboard | $3/month |
| CloudWatch Logs | ~$0.50/GB ingested |
| **Total** | **~$2-5/month** |

---

## After Deployment - What to Check

### 1. Confirm SNS Subscription
After deployment, check your email for a confirmation link:
```
Subject: AWS Notification - Subscription Confirmation
```
**You MUST click the confirmation link to receive alerts!**

### 2. View Dashboard
```
AWS Console → CloudWatch → Dashboards → devsecops-platform-dev
```

### 3. Check Alarm Status
```
AWS Console → CloudWatch → Alarms
```
All alarms should show "OK" (green) state.

---

## Architecture After Phase 6

```
┌─────────────────────────────────────────────────────────────────────┐
│                              VPC                                    │
│  ┌────────────────────────────────────────────────────────────┐    │
│  │                     Public Subnets                          │    │
│  │                    ┌─────────────┐                         │    │
│  │    Internet ──────►│     ALB     │◄──── CloudWatch         │    │
│  │                    └──────┬──────┘      Metrics            │    │
│  └───────────────────────────┼────────────────────────────────┘    │
│                              │                                      │
│  ┌───────────────────────────┼────────────────────────────────┐    │
│  │                     Private Subnets                         │    │
│  │                    ┌──────▼──────┐                         │    │
│  │                    │ ECS Fargate │◄──── CloudWatch         │    │
│  │                    └──────┬──────┘      Metrics            │    │
│  └───────────────────────────┼────────────────────────────────┘    │
│                              │                                      │
│  ┌───────────────────────────┼────────────────────────────────┐    │
│  │                      Data Subnets                           │    │
│  │                    ┌──────▼──────┐                         │    │
│  │                    │     RDS     │◄──── CloudWatch         │    │
│  │                    └─────────────┘      Metrics            │    │
│  └─────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────┘

                              │
                              ▼
              ┌───────────────────────────────┐
              │         CloudWatch            │
              │  ┌─────────────────────────┐  │
              │  │       Dashboard         │  │
              │  │  (Visual Monitoring)    │  │
              │  └─────────────────────────┘  │
              │                               │
              │  ┌─────────┬─────────┬─────┐  │
              │  │ Alarm 1 │ Alarm 2 │ ... │  │
              │  └────┬────┴────┬────┴─────┘  │
              └───────┼─────────┼─────────────┘
                      │         │
                      ▼         ▼
              ┌───────────────────────────────┐
              │         SNS Topic             │
              │    (Alert Distribution)       │
              └───────────────┬───────────────┘
                              │
                              ▼
                        ┌──────────┐
                        │  EMAIL   │
                        │  (You)   │
                        └──────────┘
```

---

## Summary

| Component | Purpose |
|-----------|---------|
| **SNS Topic** | Broadcasts alerts to subscribers |
| **CloudWatch Alarms** | Monitor metrics and trigger on thresholds |
| **CloudWatch Dashboard** | Visual view of all metrics |
| **Email Subscription** | Receive alerts in your inbox |

**Think of it as:**
- CloudWatch = Security cameras (always watching)
- Alarms = Motion sensors (detect problems)
- SNS = Alarm system (notifies you)
- Dashboard = Security monitor screen (see everything at once)
