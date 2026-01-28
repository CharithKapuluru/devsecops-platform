# AWS DevSecOps Cloud Platform - Complete Project Documentation

## Document Information

| Field | Value |
|-------|-------|
| Project Name | cloud-platform-aws |
| Author | Charith Kapuluru |
| Target Roles | Cloud Engineer, DevOps Engineer, DevSecOps Engineer |
| Estimated Duration | 8-10 weeks |
| Skill Level | Entry to Mid-Level |
| Primary Cloud | AWS |
| IaC Tool | Terraform |

---

# Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Project Objectives](#2-project-objectives)
3. [Architecture Overview](#3-architecture-overview)
4. [AWS Services Deep Dive](#4-aws-services-deep-dive)
5. [Security Architecture (DevSecOps)](#5-security-architecture-devsecops)
6. [Repository Structure](#6-repository-structure)
7. [Implementation Phases](#7-implementation-phases)
8. [Terraform Module Specifications](#8-terraform-module-specifications)
9. [CI/CD Pipeline Design](#9-cicd-pipeline-design)
10. [Monitoring and Observability](#10-monitoring-and-observability)
11. [Cost Management](#11-cost-management)
12. [Documentation Requirements](#12-documentation-requirements)
13. [Learning Outcomes](#13-learning-outcomes)
14. [Interview Talking Points](#14-interview-talking-points)

---

# 1. Executive Summary

## 1.1 What You're Building

A production-grade, multi-environment cloud platform on AWS that demonstrates enterprise-level DevSecOps practices. This platform will host a FastAPI application with:

- **Multi-environment architecture**: Development, Staging, and Production environments with proper isolation
- **Complete networking stack**: VPCs, subnets, load balancers, and DNS
- **Database layer**: PostgreSQL with high availability and automated backups
- **Caching layer**: Redis for performance optimization
- **Security-first design**: WAF, encryption, secrets management, threat detection
- **Full CI/CD automation**: From code commit to production deployment
- **Comprehensive monitoring**: Dashboards, alarms, and incident response
- **Infrastructure as Code**: 100% Terraform with reusable modules

## 1.2 Why This Project Matters

This project demonstrates skills that employers actively seek:

| Skill Category | What You'll Demonstrate |
|----------------|-------------------------|
| Cloud Architecture | Multi-tier, multi-AZ, production-grade design |
| Security | Defense in depth, compliance, threat detection |
| Automation | CI/CD, Infrastructure as Code, auto-remediation |
| Monitoring | Observability, alerting, incident response |
| Cost Management | Right-sizing, optimization, budget controls |
| Documentation | ADRs, runbooks, architecture diagrams |

## 1.3 Technologies Used

**Infrastructure:**
- AWS (25+ services)
- Terraform (modules, workspaces, remote state)
- Docker (containerization)

**Application:**
- Python 3.12
- FastAPI
- PostgreSQL
- Redis

**CI/CD:**
- GitHub Actions
- AWS CodePipeline (optional comparison)

**Security Tools:**
- Semgrep (SAST)
- Trivy (container scanning)
- AWS native security services

---

# 2. Project Objectives

## 2.1 Primary Objectives

1. **Build a production-ready AWS infrastructure** that could realistically host a startup's application
2. **Implement security at every layer** following AWS Well-Architected Framework security pillar
3. **Create reusable Terraform modules** that demonstrate IaC best practices
4. **Establish CI/CD pipelines** with proper environment promotion
5. **Set up comprehensive monitoring** with actionable alerts

## 2.2 Learning Objectives

By completing this project, you will understand:

### Networking
- How VPCs isolate resources
- Public vs private subnet design patterns
- How NAT Gateways enable outbound internet access
- Security group layering strategies
- VPC endpoints for private AWS access

### Security
- IAM role-based access with least privilege
- Encryption at rest and in transit
- Secrets management lifecycle
- Web application firewall rules
- Threat detection and response

### Compute
- Container orchestration with ECS
- Task definitions and service configuration
- Auto-scaling policies and triggers
- Rolling deployment strategies

### Data
- RDS Multi-AZ architecture
- Backup and recovery procedures
- Connection pooling and optimization
- Cache-aside patterns with Redis

### Operations
- CloudWatch metrics, logs, and alarms
- Incident response automation
- Cost allocation and optimization
- Infrastructure drift detection

---

# 3. Architecture Overview

## 3.1 High-Level Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                                    INTERNET                                          │
└─────────────────────────────────────────────────────────────────────────────────────┘
                                         │
                                         ▼
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                              EDGE / PERIMETER LAYER                                  │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐                │
│  │  Route 53   │  │ CloudFront  │  │     WAF     │  │   Shield    │                │
│  │    (DNS)    │─▶│   (CDN)     │─▶│  (Firewall) │─▶│   (DDoS)    │                │
│  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘                │
└─────────────────────────────────────────────────────────────────────────────────────┘
                                         │
                                         ▼
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                                 VPC (10.0.0.0/16)                                    │
│                                                                                      │
│  ┌────────────────────────────────────────────────────────────────────────────────┐ │
│  │                           PUBLIC SUBNETS                                        │ │
│  │  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐             │ │
│  │  │ Public Subnet A  │  │ Public Subnet B  │  │ Public Subnet C  │             │ │
│  │  │   10.0.1.0/24    │  │   10.0.2.0/24    │  │   10.0.3.0/24    │             │ │
│  │  │   (us-east-1a)   │  │   (us-east-1b)   │  │   (us-east-1c)   │             │ │
│  │  │                  │  │                  │  │                  │             │ │
│  │  │  ┌────────────┐  │  │                  │  │                  │             │ │
│  │  │  │ NAT Gateway│  │  │                  │  │                  │             │ │
│  │  │  └────────────┘  │  │                  │  │                  │             │ │
│  │  └──────────────────┘  └──────────────────┘  └──────────────────┘             │ │
│  │                                                                                 │ │
│  │                    ┌─────────────────────────────────┐                         │ │
│  │                    │    Application Load Balancer    │                         │ │
│  │                    │     (SSL/TLS Termination)       │                         │ │
│  │                    └─────────────────────────────────┘                         │ │
│  └────────────────────────────────────────────────────────────────────────────────┘ │
│                                         │                                            │
│  ┌────────────────────────────────────────────────────────────────────────────────┐ │
│  │                          PRIVATE SUBNETS (Application)                          │ │
│  │  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐             │ │
│  │  │Private Subnet A  │  │Private Subnet B  │  │Private Subnet C  │             │ │
│  │  │  10.0.11.0/24    │  │  10.0.12.0/24    │  │  10.0.13.0/24    │             │ │
│  │  │  (us-east-1a)    │  │  (us-east-1b)    │  │  (us-east-1c)    │             │ │
│  │  │                  │  │                  │  │                  │             │ │
│  │  │ ┌──────────────┐ │  │ ┌──────────────┐ │  │ ┌──────────────┐ │             │ │
│  │  │ │  ECS Task    │ │  │ │  ECS Task    │ │  │ │  ECS Task    │ │             │ │
│  │  │ │  (FastAPI)   │ │  │ │  (FastAPI)   │ │  │ │  (FastAPI)   │ │             │ │
│  │  │ └──────────────┘ │  │ └──────────────┘ │  │ └──────────────┘ │             │ │
│  │  └──────────────────┘  └──────────────────┘  └──────────────────┘             │ │
│  └────────────────────────────────────────────────────────────────────────────────┘ │
│                                         │                                            │
│  ┌────────────────────────────────────────────────────────────────────────────────┐ │
│  │                          PRIVATE SUBNETS (Data)                                 │ │
│  │  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐             │ │
│  │  │  Data Subnet A   │  │  Data Subnet B   │  │  Data Subnet C   │             │ │
│  │  │  10.0.21.0/24    │  │  10.0.22.0/24    │  │  10.0.23.0/24    │             │ │
│  │  │  (us-east-1a)    │  │  (us-east-1b)    │  │  (us-east-1c)    │             │ │
│  │  │                  │  │                  │  │                  │             │ │
│  │  │ ┌──────────────┐ │  │ ┌──────────────┐ │  │                  │             │ │
│  │  │ │ RDS Primary  │ │  │ │ RDS Standby  │ │  │                  │             │ │
│  │  │ │ (PostgreSQL) │ │  │ │ (Multi-AZ)   │ │  │                  │             │ │
│  │  │ └──────────────┘ │  │ └──────────────┘ │  │                  │             │ │
│  │  │                  │  │                  │  │                  │             │ │
│  │  │ ┌──────────────┐ │  │ ┌──────────────┐ │  │                  │             │ │
│  │  │ │ElastiCache   │ │  │ │ElastiCache   │ │  │                  │             │ │
│  │  │ │Redis Primary │ │  │ │Redis Replica │ │  │                  │             │ │
│  │  │ └──────────────┘ │  │ └──────────────┘ │  │                  │             │ │
│  │  └──────────────────┘  └──────────────────┘  └──────────────────┘             │ │
│  └────────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                      │
│  ┌────────────────────────────────────────────────────────────────────────────────┐ │
│  │                              VPC ENDPOINTS                                      │ │
│  │  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐     │ │
│  │  │   S3    │ │   ECR   │ │  Logs   │ │Secrets  │ │   SSM   │ │   KMS   │     │ │
│  │  │ Gateway │ │Interface│ │Interface│ │ Manager │ │Interface│ │Interface│     │ │
│  │  └─────────┘ └─────────┘ └─────────┘ └─────────┘ └─────────┘ └─────────┘     │ │
│  └────────────────────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────────────┐
│                              SUPPORTING SERVICES                                     │
│                                                                                      │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐  │
│  │     ECR     │ │     S3      │ │   Secrets   │ │     KMS     │ │ CloudWatch  │  │
│  │  Container  │ │  Terraform  │ │   Manager   │ │  Encryption │ │   Logs &    │  │
│  │  Registry   │ │   State     │ │             │ │    Keys     │ │   Metrics   │  │
│  └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘  │
│                                                                                      │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐  │
│  │     SNS     │ │   Lambda    │ │ EventBridge │ │  GuardDuty  │ │Security Hub │  │
│  │   Alerts    │ │ Automation  │ │  Scheduler  │ │   Threat    │ │  Compliance │  │
│  │             │ │             │ │             │ │  Detection  │ │             │  │
│  └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘  │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

## 3.2 Multi-Environment Strategy

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                              ENVIRONMENT ARCHITECTURE                                │
│                                                                                      │
│  ┌─────────────────────┐  ┌─────────────────────┐  ┌─────────────────────┐         │
│  │    DEVELOPMENT      │  │      STAGING        │  │     PRODUCTION      │         │
│  │                     │  │                     │  │                     │         │
│  │  VPC: 10.0.0.0/16   │  │  VPC: 10.1.0.0/16   │  │  VPC: 10.2.0.0/16   │         │
│  │                     │  │                     │  │                     │         │
│  │  ┌───────────────┐  │  │  ┌───────────────┐  │  │  ┌───────────────┐  │         │
│  │  │ ECS: 1 task   │  │  │  │ ECS: 2 tasks  │  │  │  │ ECS: 3+ tasks │  │         │
│  │  │ 0.25 vCPU     │  │  │  │ 0.5 vCPU      │  │  │  │ 1 vCPU        │  │         │
│  │  │ 0.5 GB RAM    │  │  │  │ 1 GB RAM      │  │  │  │ 2 GB RAM      │  │         │
│  │  └───────────────┘  │  │  └───────────────┘  │  │  └───────────────┘  │         │
│  │                     │  │                     │  │                     │         │
│  │  ┌───────────────┐  │  │  ┌───────────────┐  │  │  ┌───────────────┐  │         │
│  │  │RDS: db.t3.micro│ │  │  │RDS: db.t3.small│ │  │  │RDS: db.t3.medium│         │
│  │  │ Single-AZ     │  │  │  │ Single-AZ     │  │  │  │ Multi-AZ      │  │         │
│  │  │ 7-day backup  │  │  │  │ 14-day backup │  │  │  │ 30-day backup │  │         │
│  │  └───────────────┘  │  │  └───────────────┘  │  │  └───────────────┘  │         │
│  │                     │  │                     │  │                     │         │
│  │  ┌───────────────┐  │  │  ┌───────────────┐  │  │  ┌───────────────┐  │         │
│  │  │Redis: t3.micro│  │  │  │Redis: t3.small│  │  │  │Redis: t3.medium│ │         │
│  │  │ No replica    │  │  │  │ No replica    │  │  │  │ With replica  │  │         │
│  │  └───────────────┘  │  │  └───────────────┘  │  │  └───────────────┘  │         │
│  │                     │  │                     │  │                     │         │
│  │  Auto-shutdown:     │  │  Auto-shutdown:     │  │  24/7 operation     │         │
│  │  8PM-8AM EST        │  │  None               │  │                     │         │
│  │                     │  │                     │  │                     │         │
│  │  Deploy: Auto       │  │  Deploy: Auto       │  │  Deploy: Manual     │         │
│  │  on push            │  │  after dev success  │  │  approval required  │         │
│  └─────────────────────┘  └─────────────────────┘  └─────────────────────┘         │
│                                                                                      │
│  ┌─────────────────────────────────────────────────────────────────────────────┐   │
│  │                         SHARED RESOURCES                                     │   │
│  │                                                                              │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐    │   │
│  │  │     ECR      │  │  S3 State    │  │  Route 53    │  │   IAM Roles  │    │   │
│  │  │  (Images)    │  │  (Terraform) │  │  (DNS Zone)  │  │   (CI/CD)    │    │   │
│  │  └──────────────┘  └──────────────┘  └──────────────┘  └──────────────┘    │   │
│  └─────────────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

## 3.3 Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                                  REQUEST FLOW                                        │
└─────────────────────────────────────────────────────────────────────────────────────┘

User Request
     │
     ▼
┌─────────────┐
│  Route 53   │  DNS resolution: api.yourname.com → CloudFront
└─────────────┘
     │
     ▼
┌─────────────┐
│ CloudFront  │  Edge caching, SSL termination (optional, can skip for API)
└─────────────┘
     │
     ▼
┌─────────────┐
│    WAF      │  Check rules: Rate limiting, SQL injection, XSS, Bot detection
└─────────────┘
     │
     ├──── BLOCKED ──▶ Return 403 Forbidden
     │
     ▼ (ALLOWED)
┌─────────────┐
│    ALB      │  Route to target group, health check validation
└─────────────┘
     │
     ▼
┌─────────────┐
│  ECS Task   │  Application container (FastAPI)
│  (FastAPI)  │
└─────────────┘
     │
     ├──── Need cached data? ──▶ ┌─────────────┐
     │                           │    Redis    │  Cache hit → Return cached
     │                           └─────────────┘  Cache miss → Continue
     │
     ▼
┌─────────────┐
│ PostgreSQL  │  Query database
│    RDS      │
└─────────────┘
     │
     ▼
Response flows back through the same path


┌─────────────────────────────────────────────────────────────────────────────────────┐
│                              SECRETS FLOW                                            │
└─────────────────────────────────────────────────────────────────────────────────────┘

ECS Task Startup
     │
     ▼
┌─────────────────────┐
│  Task Role assumes  │  IAM role attached to task definition
│  IAM permissions    │
└─────────────────────┘
     │
     ▼
┌─────────────────────┐
│  Secrets Manager    │  Fetch database credentials, API keys
│  API call (via VPC  │  Uses VPC endpoint - no internet traffic
│  endpoint)          │
└─────────────────────┘
     │
     ▼
┌─────────────────────┐
│  KMS decryption     │  Secrets are encrypted with CMK
└─────────────────────┘
     │
     ▼
┌─────────────────────┐
│  Inject into        │  Credentials available as environment variables
│  container env      │
└─────────────────────┘


┌─────────────────────────────────────────────────────────────────────────────────────┐
│                              LOGGING FLOW                                            │
└─────────────────────────────────────────────────────────────────────────────────────┘

Application Log
     │
     ▼
┌─────────────────────┐
│  CloudWatch Logs    │  Log group: /ecs/{environment}/fastapi
│  (via awslogs       │  Retention: 30 days (dev), 90 days (prod)
│  driver)            │
└─────────────────────┘
     │
     ├──── Metric Filter ──▶ ┌─────────────────────┐
     │     (ERROR count)     │  CloudWatch Metric  │
     │                       └─────────────────────┘
     │                                │
     │                                ▼
     │                       ┌─────────────────────┐
     │                       │  CloudWatch Alarm   │  Threshold: > 10 errors/min
     │                       └─────────────────────┘
     │                                │
     │                                ▼
     │                       ┌─────────────────────┐
     │                       │       SNS           │  Send alert
     │                       └─────────────────────┘
     │                                │
     │                                ├──▶ Email
     │                                ├──▶ Slack (via Lambda)
     │                                └──▶ PagerDuty (prod only)
     │
     ▼
┌─────────────────────┐
│  S3 Archive         │  Long-term storage (optional, for compliance)
│  (Lifecycle policy) │  Glacier after 90 days
└─────────────────────┘
```

---

# 4. AWS Services Deep Dive

This section explains every AWS service used in this project, why it's needed, and how it fits into the architecture.

---

## 4.1 Networking Services

### 4.1.1 Amazon VPC (Virtual Private Cloud)

**What it is:**
A logically isolated virtual network that you define in AWS. Think of it as your own private data center in the cloud.

**Why we need it:**
- Isolates your resources from other AWS customers
- Gives you complete control over IP addressing
- Enables you to define security boundaries
- Required for most AWS services (RDS, ECS, ElastiCache)

**Key concepts:**
| Concept | Explanation |
|---------|-------------|
| CIDR Block | IP address range (e.g., 10.0.0.0/16 gives you 65,536 IPs) |
| Tenancy | Default (shared hardware) vs Dedicated (your own hardware) |
| DNS Hostnames | Enables DNS names for EC2 instances |
| DNS Support | Enables DNS resolution within the VPC |

**In this project:**
- One VPC per environment (dev, staging, prod)
- CIDR: 10.0.0.0/16 (dev), 10.1.0.0/16 (staging), 10.2.0.0/16 (prod)
- Enables DNS hostnames and support for service discovery

**What you'll learn:**
- How to plan IP address space
- VPC peering (if connecting environments)
- VPC Flow Logs for network troubleshooting

---

### 4.1.2 Subnets

**What it is:**
A range of IP addresses within your VPC. Subnets allow you to group resources based on security and operational needs.

**Why we need it:**
- Separate public-facing resources from private resources
- Deploy across multiple Availability Zones for high availability
- Apply different network ACLs to different subnets

**Types of subnets in this project:**

| Subnet Type | Purpose | Internet Access | Example Resources |
|-------------|---------|-----------------|-------------------|
| Public | Resources that need direct internet access | Yes (via IGW) | ALB, NAT Gateway, Bastion (if needed) |
| Private (App) | Application tier that needs outbound internet | Outbound only (via NAT) | ECS tasks, Lambda |
| Private (Data) | Database tier with no internet access | No | RDS, ElastiCache |

**Subnet design:**
```
VPC: 10.0.0.0/16

Public Subnets:
  - 10.0.1.0/24  (AZ-a) - 256 IPs
  - 10.0.2.0/24  (AZ-b) - 256 IPs
  - 10.0.3.0/24  (AZ-c) - 256 IPs

Private Subnets (Application):
  - 10.0.11.0/24 (AZ-a) - 256 IPs
  - 10.0.12.0/24 (AZ-b) - 256 IPs
  - 10.0.13.0/24 (AZ-c) - 256 IPs

Private Subnets (Data):
  - 10.0.21.0/24 (AZ-a) - 256 IPs
  - 10.0.22.0/24 (AZ-b) - 256 IPs
  - 10.0.23.0/24 (AZ-c) - 256 IPs
```

**What you'll learn:**
- CIDR notation and subnet math
- Why 3 AZs provides better availability than 2
- How subnet size affects scalability

---

### 4.1.3 Internet Gateway (IGW)

**What it is:**
A horizontally scaled, redundant, and highly available VPC component that allows communication between your VPC and the internet.

**Why we need it:**
- Required for any resource that needs to receive traffic from the internet
- Enables the ALB to receive incoming requests
- Enables resources in public subnets to have public IPs

**Key points:**
- One IGW per VPC
- Automatically highly available and scalable
- No bandwidth constraints
- Free (no hourly charge)

**In this project:**
- Attached to each environment's VPC
- Public subnets have a route to the IGW (0.0.0.0/0 → IGW)

---

### 4.1.4 NAT Gateway

**What it is:**
A managed service that enables instances in private subnets to connect to the internet while preventing the internet from initiating connections to those instances.

**Why we need it:**
- ECS tasks need to pull Docker images from ECR (if not using VPC endpoints)
- Applications may need to call external APIs
- Security updates and package downloads

**Key points:**
| Aspect | Details |
|--------|---------|
| Availability | Deploy in public subnet, one per AZ for HA |
| Bandwidth | Up to 45 Gbps, scales automatically |
| Cost | ~$0.045/hour + $0.045/GB processed |
| Alternative | NAT Instance (cheaper but self-managed) |

**In this project:**
- Dev: 1 NAT Gateway (cost savings, lower availability)
- Staging: 1 NAT Gateway
- Prod: 3 NAT Gateways (one per AZ for high availability)

**Cost optimization note:**
NAT Gateway is one of the most expensive networking components. We reduce costs by:
1. Using VPC endpoints for AWS services (S3, ECR, CloudWatch)
2. Single NAT Gateway in non-prod environments
3. Shutting down dev environment outside business hours

---

### 4.1.5 Route Tables

**What it is:**
A set of rules (routes) that determine where network traffic is directed.

**Why we need it:**
- Direct traffic to the right destination (internet, NAT, VPC endpoints)
- Each subnet must be associated with a route table
- Control traffic flow between subnets

**Route tables in this project:**

**Public Route Table:**
| Destination | Target | Purpose |
|-------------|--------|---------|
| 10.0.0.0/16 | local | Traffic within VPC |
| 0.0.0.0/0 | igw-xxx | Internet-bound traffic |

**Private Route Table:**
| Destination | Target | Purpose |
|-------------|--------|---------|
| 10.0.0.0/16 | local | Traffic within VPC |
| 0.0.0.0/0 | nat-xxx | Internet-bound traffic via NAT |
| pl-xxx (S3) | vpce-xxx | S3 traffic via endpoint |

**Data Route Table:**
| Destination | Target | Purpose |
|-------------|--------|---------|
| 10.0.0.0/16 | local | Traffic within VPC only |

---

### 4.1.6 Security Groups

**What it is:**
A virtual firewall that controls inbound and outbound traffic at the instance/resource level. Security groups are stateful (if you allow inbound, the response is automatically allowed outbound).

**Why we need it:**
- Primary defense mechanism for resources
- Allow only necessary traffic
- Layered security (each tier has its own security group)

**Security groups in this project:**

**ALB Security Group:**
```
Inbound:
  - HTTPS (443) from 0.0.0.0/0       # Public internet
  - HTTP (80) from 0.0.0.0/0         # Redirect to HTTPS
  
Outbound:
  - TCP 8000 to App Security Group    # Forward to application
```

**Application Security Group:**
```
Inbound:
  - TCP 8000 from ALB Security Group  # Only from load balancer
  
Outbound:
  - TCP 5432 to RDS Security Group    # Database access
  - TCP 6379 to Redis Security Group  # Cache access
  - HTTPS (443) to VPC Endpoints      # AWS API calls
```

**RDS Security Group:**
```
Inbound:
  - TCP 5432 from App Security Group  # Only from application
  
Outbound:
  - None (databases don't initiate connections)
```

**Redis Security Group:**
```
Inbound:
  - TCP 6379 from App Security Group  # Only from application
  
Outbound:
  - None
```

**VPC Endpoint Security Group:**
```
Inbound:
  - HTTPS (443) from App Security Group
  - HTTPS (443) from 10.0.0.0/16      # All VPC traffic
  
Outbound:
  - All traffic (endpoints proxy to AWS services)
```

**What you'll learn:**
- Defense in depth strategy
- Why security groups reference other security groups (not IP ranges)
- Troubleshooting connectivity issues

---

### 4.1.7 Network ACLs (NACLs)

**What it is:**
An optional layer of security that acts as a firewall at the subnet level. NACLs are stateless (you must explicitly allow both inbound and outbound traffic).

**Why we need it:**
- Additional security layer (defense in depth)
- Block specific IP ranges (e.g., known malicious IPs)
- Compliance requirements may mandate subnet-level controls

**Key differences from Security Groups:**

| Aspect | Security Group | NACL |
|--------|----------------|------|
| Level | Instance/Resource | Subnet |
| State | Stateful | Stateless |
| Rules | Allow only | Allow and Deny |
| Evaluation | All rules evaluated | Rules evaluated in order |
| Default | Deny all inbound, allow all outbound | Allow all |

**In this project:**
- Public subnet NACL: Allow HTTP/HTTPS inbound, ephemeral ports outbound
- Private subnet NACL: Allow traffic from public subnets only
- Data subnet NACL: Allow traffic from private subnets only

---

### 4.1.8 VPC Endpoints

**What it is:**
Enables private connections between your VPC and AWS services without requiring an internet gateway, NAT device, or VPN connection.

**Why we need it:**
- Improved security (traffic doesn't traverse the internet)
- Reduced NAT Gateway costs (AWS service traffic is free via endpoints)
- Lower latency
- Required for private subnets without NAT Gateway

**Types of endpoints:**

| Type | Use Case | Example Services |
|------|----------|------------------|
| Gateway | S3, DynamoDB | Free, uses route tables |
| Interface | Most AWS services | Creates ENI, costs ~$0.01/hour |

**Endpoints in this project:**

| Endpoint | Type | Why Needed |
|----------|------|------------|
| S3 | Gateway | Terraform state, backups, logs |
| ECR API | Interface | Docker image metadata |
| ECR DKR | Interface | Docker image layers |
| CloudWatch Logs | Interface | Application logging |
| Secrets Manager | Interface | Fetch secrets at runtime |
| SSM | Interface | Parameter Store, Session Manager |
| KMS | Interface | Decrypt secrets |
| STS | Interface | IAM role assumption |

**Cost impact:**
Without VPC endpoints, all AWS API calls go through NAT Gateway at $0.045/GB. With endpoints:
- Gateway endpoints: Free
- Interface endpoints: ~$7/month each but save on NAT costs

---

### 4.1.9 Elastic IP (EIP)

**What it is:**
A static, public IPv4 address designed for dynamic cloud computing.

**Why we need it:**
- NAT Gateway requires an EIP
- Provides a consistent public IP (useful for allowlisting)

**In this project:**
- One EIP per NAT Gateway
- Tagged for identification and cost allocation

---

## 4.2 Compute Services

### 4.2.1 Amazon ECS (Elastic Container Service)

**What it is:**
A fully managed container orchestration service that makes it easy to deploy, manage, and scale containerized applications.

**Why we need it:**
- Run Docker containers without managing servers
- Integrates with ALB, CloudWatch, IAM
- Supports Fargate (serverless) or EC2 launch types

**Key concepts:**

| Concept | Explanation |
|---------|-------------|
| Cluster | Logical grouping of tasks or services |
| Task Definition | Blueprint for your application (like docker-compose) |
| Task | Running instance of a task definition |
| Service | Maintains desired number of tasks, handles deployments |

**ECS vs EKS:**

| Aspect | ECS | EKS |
|--------|-----|-----|
| Learning curve | Lower | Higher |
| Kubernetes compatibility | No | Yes |
| AWS integration | Deeper | Good |
| Portability | AWS only | Multi-cloud |
| Cost | Lower | Higher ($0.10/hr for control plane) |

**In this project:**
- ECS with Fargate launch type (serverless)
- One cluster per environment
- One service running the FastAPI application
- Rolling deployment strategy

---

### 4.2.2 AWS Fargate

**What it is:**
A serverless compute engine for containers that works with ECS (and EKS). You don't need to provision, configure, or scale clusters of virtual machines.

**Why we need it:**
- No server management
- Pay only for what you use
- Automatic scaling
- Each task runs in its own isolated environment

**Fargate pricing:**
| Resource | Price (us-east-1) |
|----------|-------------------|
| vCPU | $0.04048 per vCPU per hour |
| Memory | $0.004445 per GB per hour |

**Task sizes in this project:**

| Environment | vCPU | Memory | Monthly Cost (2 tasks, 24/7) |
|-------------|------|--------|------------------------------|
| Dev | 0.25 | 0.5 GB | ~$15 |
| Staging | 0.5 | 1 GB | ~$30 |
| Prod | 1 | 2 GB | ~$100 (3 tasks min) |

---

### 4.2.3 Amazon ECR (Elastic Container Registry)

**What it is:**
A fully managed Docker container registry that makes it easy to store, manage, and deploy Docker container images.

**Why we need it:**
- Private registry for your Docker images
- Integrates with ECS, EKS, and IAM
- Image scanning for vulnerabilities
- Lifecycle policies to manage image retention

**Key features we'll use:**
- Image scanning on push (vulnerability detection)
- Lifecycle policies (keep last 10 images, delete untagged after 7 days)
- Cross-region replication (optional, for disaster recovery)

**In this project:**
- One ECR repository shared across environments
- Images tagged with git commit SHA and environment
- Lifecycle policy to control costs

---

### 4.2.4 Application Load Balancer (ALB)

**What it is:**
A load balancer that operates at the application layer (Layer 7), making routing decisions based on content of the request.

**Why we need it:**
- Distribute traffic across multiple ECS tasks
- SSL/TLS termination
- Health checks to route traffic only to healthy targets
- Path-based and host-based routing

**Key components:**

| Component | Purpose |
|-----------|---------|
| Listener | Checks for connection requests on a port/protocol |
| Target Group | Routes requests to registered targets |
| Health Check | Determines if targets can receive traffic |
| Rules | Determine how to route requests |

**In this project:**
- One ALB per environment
- HTTPS listener (443) with SSL certificate from ACM
- HTTP listener (80) redirects to HTTPS
- Health check: GET /health, expect 200
- Target group: ECS tasks on port 8000

**ALB vs NLB:**

| Aspect | ALB | NLB |
|--------|-----|-----|
| Layer | 7 (Application) | 4 (Transport) |
| Protocols | HTTP, HTTPS, gRPC | TCP, UDP, TLS |
| Features | Path routing, host routing | Static IP, low latency |
| Use case | Web applications | Non-HTTP, extreme performance |

---

### 4.2.5 AWS Lambda

**What it is:**
A serverless compute service that lets you run code without provisioning or managing servers.

**Why we need it:**
- Automation tasks (scale down dev at night)
- Event-driven processing (respond to alerts)
- Custom CloudWatch metrics
- Slack notifications for alerts

**Lambda functions in this project:**

| Function | Trigger | Purpose |
|----------|---------|---------|
| scale-down-dev | EventBridge (8 PM EST) | Stop dev resources to save costs |
| scale-up-dev | EventBridge (8 AM EST) | Start dev resources |
| slack-notifier | SNS | Send alerts to Slack |
| auto-remediate | GuardDuty findings | Automatic security response |

**Lambda pricing:**
- First 1 million requests/month: Free
- $0.20 per 1 million requests after
- $0.0000166667 per GB-second of compute

---

## 4.3 Database Services

### 4.3.1 Amazon RDS (PostgreSQL)

**What it is:**
A managed relational database service that makes it easy to set up, operate, and scale a relational database in the cloud.

**Why we need it:**
- Managed database (AWS handles patching, backups, recovery)
- Multi-AZ for high availability
- Automated backups and point-in-time recovery
- Performance Insights for monitoring

**Key features:**

| Feature | Explanation |
|---------|-------------|
| Multi-AZ | Synchronous standby replica in different AZ |
| Read Replicas | Asynchronous replicas for read scaling |
| Automated Backups | Daily snapshots + transaction logs |
| PITR | Point-in-time recovery to any second |
| Performance Insights | Database performance monitoring |

**Configuration in this project:**

| Setting | Dev | Staging | Prod |
|---------|-----|---------|------|
| Instance Class | db.t3.micro | db.t3.small | db.t3.medium |
| Storage | 20 GB | 50 GB | 100 GB |
| Multi-AZ | No | No | Yes |
| Backup Retention | 7 days | 14 days | 30 days |
| Encryption | Yes | Yes | Yes |
| Performance Insights | No | Yes | Yes |
| Delete Protection | No | No | Yes |

**What you'll learn:**
- Subnet groups for RDS
- Parameter groups for tuning
- Connection pooling with pgBouncer or application-level
- Backup and restore procedures

---

### 4.3.2 Amazon ElastiCache (Redis)

**What it is:**
A fully managed in-memory data store and cache service.

**Why we need it:**
- Reduce database load (cache frequently accessed data)
- Session storage
- Rate limiting
- Microsecond latency

**Redis vs Memcached:**

| Aspect | Redis | Memcached |
|--------|-------|-----------|
| Data structures | Rich (strings, lists, sets, hashes) | Simple key-value |
| Persistence | Yes | No |
| Replication | Yes | No |
| Pub/Sub | Yes | No |
| Use case | Feature-rich caching | Simple, high-throughput |

**Configuration in this project:**

| Setting | Dev | Staging | Prod |
|---------|-----|---------|------|
| Node Type | cache.t3.micro | cache.t3.small | cache.t3.medium |
| Replicas | 0 | 0 | 1 |
| Multi-AZ | No | No | Yes |
| Encryption at rest | Yes | Yes | Yes |
| Encryption in transit | Yes | Yes | Yes |

---

## 4.4 Storage Services

### 4.4.1 Amazon S3 (Simple Storage Service)

**What it is:**
An object storage service offering industry-leading scalability, data availability, security, and performance.

**Why we need it:**
- Terraform state storage
- Application logs archival
- Database backup storage
- Static assets (if needed)

**S3 buckets in this project:**

| Bucket | Purpose | Versioning | Encryption |
|--------|---------|------------|------------|
| {project}-terraform-state | Terraform remote state | Yes | Yes |
| {project}-logs | CloudWatch logs export | No | Yes |
| {project}-backups | RDS snapshots export | Yes | Yes |

**Key features we'll use:**
- Versioning (for Terraform state)
- Server-side encryption (SSE-S3 or SSE-KMS)
- Lifecycle policies (move to Glacier after 90 days)
- Bucket policies (restrict access)

---

### 4.4.2 Amazon DynamoDB

**What it is:**
A fully managed NoSQL database service that provides fast and predictable performance with seamless scalability.

**Why we need it:**
- Terraform state locking (prevents concurrent modifications)
- Serverless, pay-per-request pricing

**In this project:**
- Single table for Terraform state locking
- On-demand capacity mode
- Minimal cost (~$0.25/month)

---

## 4.5 Security Services

### 4.5.1 AWS IAM (Identity and Access Management)

**What it is:**
The service that controls who can do what in your AWS account.

**Why we need it:**
- Control access to AWS resources
- Define what each service can do
- Enable secure CI/CD deployments
- Audit who did what

**Key concepts:**

| Concept | Explanation |
|---------|-------------|
| User | A person or application that interacts with AWS |
| Role | An identity with permissions that can be assumed |
| Policy | A document that defines permissions |
| Trust Policy | Defines who can assume a role |

**IAM roles in this project:**

| Role | Purpose | Trust Policy |
|------|---------|--------------|
| ECSTaskExecutionRole | Pull images, write logs | ecs-tasks.amazonaws.com |
| ECSTaskRole | App runtime permissions | ecs-tasks.amazonaws.com |
| GitHubActionsRole | CI/CD deployment | token.actions.githubusercontent.com |
| LambdaExecutionRole | Lambda function permissions | lambda.amazonaws.com |
| RDSMonitoringRole | Enhanced monitoring | monitoring.rds.amazonaws.com |

**Least privilege principle:**
Each role gets only the permissions it needs. For example:
- ECSTaskRole can read specific secrets, not all secrets
- GitHubActionsRole can update specific ECS services, not delete them

---

### 4.5.2 AWS KMS (Key Management Service)

**What it is:**
A managed service that makes it easy to create and control the encryption keys used to encrypt your data.

**Why we need it:**
- Encrypt secrets in Secrets Manager
- Encrypt RDS databases
- Encrypt S3 buckets
- Encrypt EBS volumes (if using EC2)

**Key types:**

| Type | Management | Cost |
|------|------------|------|
| AWS Managed | AWS manages rotation | Free |
| Customer Managed (CMK) | You control policies, rotation | $1/month + API calls |

**In this project:**
- One CMK per environment
- Key policy restricts who can use the key
- Automatic annual rotation enabled

---

### 4.5.3 AWS Secrets Manager

**What it is:**
A service to securely store, manage, and retrieve secrets like database credentials, API keys, and tokens.

**Why we need it:**
- Never hardcode credentials
- Automatic rotation of secrets
- Fine-grained access control
- Audit trail via CloudTrail

**Secrets in this project:**

| Secret | Contents | Rotation |
|--------|----------|----------|
| /{env}/database/credentials | username, password, host, port | 30 days (prod) |
| /{env}/redis/auth-token | AUTH token | Manual |
| /{env}/app/api-keys | External API keys | Manual |

**How ECS accesses secrets:**
1. Task definition references secret ARN
2. ECS agent assumes task execution role
3. Agent calls Secrets Manager API
4. KMS decrypts the secret
5. Secret injected as environment variable

---

### 4.5.4 AWS WAF (Web Application Firewall)

**What it is:**
A web application firewall that helps protect your web applications from common web exploits.

**Why we need it:**
- Block SQL injection attacks
- Block cross-site scripting (XSS)
- Rate limiting to prevent DDoS
- Geo-blocking (if needed)
- Bot protection

**WAF rules in this project:**

| Rule | Purpose | Action |
|------|---------|--------|
| AWSManagedRulesCommonRuleSet | OWASP Top 10 | Block |
| AWSManagedRulesKnownBadInputsRuleSet | Known malicious patterns | Block |
| AWSManagedRulesSQLiRuleSet | SQL injection | Block |
| RateLimit | Max 2000 requests/5 min per IP | Block |
| GeoBlock | Block specific countries (optional) | Block |

**WAF pricing:**
- $5/month per Web ACL
- $1/month per rule
- $0.60 per million requests

---

### 4.5.5 AWS Shield

**What it is:**
A managed DDoS protection service.

**Why we need it:**
- Automatic protection against common DDoS attacks
- Standard tier is free and automatic
- Advanced tier provides additional protection and support

**Tiers:**

| Tier | Cost | Features |
|------|------|----------|
| Standard | Free | Automatic L3/L4 protection |
| Advanced | $3,000/month | L7 protection, 24/7 DRT support, cost protection |

**In this project:**
- Shield Standard (automatic, free)
- Shield Advanced only if handling sensitive data or high-value targets

---

### 4.5.6 AWS Certificate Manager (ACM)

**What it is:**
A service to provision, manage, and deploy SSL/TLS certificates.

**Why we need it:**
- HTTPS for the ALB
- Free SSL certificates
- Automatic renewal
- No certificate management hassle

**In this project:**
- One certificate for *.yourname.com
- DNS validation via Route 53
- Attached to ALB HTTPS listener

---

### 4.5.7 Amazon GuardDuty

**What it is:**
A threat detection service that continuously monitors for malicious activity and unauthorized behavior.

**Why we need it:**
- Detect compromised credentials
- Detect cryptocurrency mining
- Detect data exfiltration
- Detect reconnaissance activities

**How it works:**
- Analyzes CloudTrail, VPC Flow Logs, DNS logs
- Uses machine learning to identify threats
- Generates findings with severity levels
- Integrates with EventBridge for automation

**In this project:**
- Enabled in all environments
- Findings sent to Security Hub
- High-severity findings trigger Lambda for auto-remediation

**Pricing:**
- ~$4/million CloudTrail events
- ~$1/GB of VPC Flow Logs
- Typically $10-50/month for small workloads

---

### 4.5.8 AWS Security Hub

**What it is:**
A service that aggregates security findings from multiple AWS services and third-party tools into a single dashboard.

**Why we need it:**
- Centralized view of security posture
- Compliance standards (CIS, PCI-DSS, etc.)
- Automated compliance checks
- Integration with GuardDuty, Inspector, Macie

**Security standards enabled:**
- AWS Foundational Security Best Practices
- CIS AWS Foundations Benchmark

**In this project:**
- Enabled in all environments
- Findings aggregated from GuardDuty, Config
- Weekly security posture report

---

### 4.5.9 AWS CloudTrail

**What it is:**
A service that enables governance, compliance, operational auditing, and risk auditing of your AWS account.

**Why we need it:**
- Record all API calls in your account
- Security analysis and troubleshooting
- Compliance requirements
- Forensic investigation after incidents

**Configuration:**
- Multi-region trail
- Log all management events
- Log S3 data events for sensitive buckets
- Encrypted with KMS
- Stored in S3 with lifecycle policy

---

### 4.5.10 AWS Config

**What it is:**
A service that enables you to assess, audit, and evaluate the configurations of your AWS resources.

**Why we need it:**
- Track configuration changes over time
- Evaluate compliance against rules
- Automatic remediation of non-compliant resources

**Config rules in this project:**

| Rule | What it checks |
|------|----------------|
| s3-bucket-public-read-prohibited | S3 buckets aren't public |
| rds-instance-public-access-check | RDS not publicly accessible |
| encrypted-volumes | EBS volumes are encrypted |
| iam-root-access-key-check | Root account has no access keys |
| vpc-flow-logs-enabled | VPC flow logs are enabled |
| cloudtrail-enabled | CloudTrail is enabled |

---

### 4.5.11 IAM Access Analyzer

**What it is:**
A service that analyzes resource policies to help you identify resources that are shared with external entities.

**Why we need it:**
- Find unintended public access
- Validate IAM policies before deployment
- Continuous monitoring for policy changes

**In this project:**
- Analyzer enabled for the account
- Findings reviewed weekly
- Integrated with Security Hub

---

### 4.5.12 Amazon Inspector

**What it is:**
An automated vulnerability management service that continually scans AWS workloads for software vulnerabilities and unintended network exposure.

**Why we need it:**
- Scan ECR images for vulnerabilities
- Scan running containers
- Network reachability analysis

**In this project:**
- Enabled for ECR scanning
- Scan on image push
- Findings sent to Security Hub

---

## 4.6 Monitoring and Logging Services

### 4.6.1 Amazon CloudWatch

**What it is:**
A monitoring and observability service that provides data and actionable insights for AWS resources and applications.

**Components we'll use:**

| Component | Purpose |
|-----------|---------|
| Metrics | Numerical data points over time |
| Logs | Text-based log data |
| Alarms | Automated actions based on thresholds |
| Dashboards | Visualization of metrics |
| Log Insights | Query and analyze logs |
| Events/EventBridge | React to changes in AWS resources |

**Metrics we'll monitor:**

| Service | Metrics |
|---------|---------|
| ALB | RequestCount, TargetResponseTime, HTTPCode_Target_5XX |
| ECS | CPUUtilization, MemoryUtilization |
| RDS | CPUUtilization, DatabaseConnections, FreeStorageSpace |
| Redis | CacheHits, CacheMisses, CurrConnections |

**Log groups:**
- /ecs/{env}/fastapi - Application logs
- /aws/rds/instance/{instance}/postgresql - Database logs
- /aws/lambda/{function} - Lambda logs
- VPC flow logs

---

### 4.6.2 Amazon SNS (Simple Notification Service)

**What it is:**
A fully managed pub/sub messaging service for application-to-application and application-to-person messaging.

**Why we need it:**
- Send alerts from CloudWatch alarms
- Fan out notifications to multiple endpoints
- Trigger Lambda functions

**SNS topics in this project:**

| Topic | Subscribers | Purpose |
|-------|-------------|---------|
| {env}-critical-alerts | Email, PagerDuty, Lambda | P1 incidents |
| {env}-warning-alerts | Email, Slack | P2 issues |
| {env}-info-alerts | Slack | Informational |

---

## 4.7 DNS and Content Delivery

### 4.7.1 Amazon Route 53

**What it is:**
A highly available and scalable Domain Name System (DNS) web service.

**Why we need it:**
- DNS for your domain
- Health checks and failover
- Integration with ACM for certificate validation

**DNS records in this project:**

| Record | Type | Value |
|--------|------|-------|
| api.dev.yourname.com | A (Alias) | Dev ALB |
| api.staging.yourname.com | A (Alias) | Staging ALB |
| api.yourname.com | A (Alias) | Prod ALB |
| _acme-challenge.yourname.com | CNAME | ACM validation |

---

### 4.7.2 Amazon CloudFront (Optional)

**What it is:**
A fast content delivery network (CDN) service that securely delivers data, videos, applications, and APIs to customers globally.

**Why we might need it:**
- Cache API responses at the edge
- Additional DDoS protection
- Global distribution for international users

**In this project:**
- Optional for API (most value for static content)
- If used, placed in front of ALB
- Can enable WAF at CloudFront level

---

## 4.8 Automation Services

### 4.8.1 Amazon EventBridge

**What it is:**
A serverless event bus that makes it easier to build event-driven applications.

**Why we need it:**
- Schedule Lambda functions (cron jobs)
- React to AWS events (GuardDuty findings)
- Decouple event producers and consumers

**Rules in this project:**

| Rule | Schedule/Event | Target |
|------|----------------|--------|
| dev-scale-down | cron(0 1 ? * MON-FRI *) | Lambda |
| dev-scale-up | cron(0 13 ? * MON-FRI *) | Lambda |
| guardduty-findings | GuardDuty finding | Lambda |
| config-compliance | Config rule change | SNS |

---

### 4.8.2 AWS Systems Manager (SSM)

**What it is:**
A service that provides a unified user interface to view operational data and automate operational tasks.

**Components we'll use:**

| Component | Purpose |
|-----------|---------|
| Parameter Store | Store configuration values |
| Session Manager | Secure shell access without bastion |
| Run Command | Execute commands across instances |

**In this project:**
- Parameter Store for non-sensitive config (Secrets Manager for secrets)
- Session Manager for debugging (if needed)

---

# 5. Security Architecture (DevSecOps)

This section provides a comprehensive view of the security implementation, which is critical for DevSecOps roles.

## 5.1 Security Layers (Defense in Depth)

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                               SECURITY LAYERS                                        │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│  Layer 1: PERIMETER SECURITY                                                         │
│  ┌─────────────────────────────────────────────────────────────────────────────┐   │
│  │ • Route 53 DNSSEC (optional)                                                 │   │
│  │ • CloudFront with WAF                                                        │   │
│  │ • AWS Shield (Standard/Advanced)                                             │   │
│  │ • Rate limiting, geo-blocking                                                │   │
│  │ • Bot detection and mitigation                                               │   │
│  └─────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                      │
│  Layer 2: NETWORK SECURITY                                                           │
│  ┌─────────────────────────────────────────────────────────────────────────────┐   │
│  │ • VPC isolation (separate VPC per environment)                               │   │
│  │ • Subnet segmentation (public/private/data)                                  │   │
│  │ • Network ACLs (stateless subnet firewall)                                   │   │
│  │ • Security Groups (stateful instance firewall)                               │   │
│  │ • VPC Flow Logs (network traffic monitoring)                                 │   │
│  │ • VPC Endpoints (private AWS access)                                         │   │
│  └─────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                      │
│  Layer 3: IDENTITY & ACCESS MANAGEMENT                                               │
│  ┌─────────────────────────────────────────────────────────────────────────────┐   │
│  │ • IAM roles with least privilege                                             │   │
│  │ • OIDC federation for CI/CD (no long-lived credentials)                      │   │
│  │ • Service-linked roles                                                       │   │
│  │ • Resource-based policies                                                    │   │
│  │ • IAM Access Analyzer                                                        │   │
│  │ • MFA enforcement (for console users)                                        │   │
│  └─────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                      │
│  Layer 4: DATA PROTECTION                                                            │
│  ┌─────────────────────────────────────────────────────────────────────────────┐   │
│  │ • Encryption at rest (KMS CMK)                                               │   │
│  │   - RDS encrypted                                                            │   │
│  │   - ElastiCache encrypted                                                    │   │
│  │   - S3 encrypted                                                             │   │
│  │   - Secrets Manager encrypted                                                │   │
│  │ • Encryption in transit (TLS 1.2+)                                           │   │
│  │   - HTTPS on ALB                                                             │   │
│  │   - SSL to RDS                                                               │   │
│  │   - TLS to Redis                                                             │   │
│  │ • Secrets management (Secrets Manager with rotation)                         │   │
│  └─────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                      │
│  Layer 5: APPLICATION SECURITY                                                       │
│  ┌─────────────────────────────────────────────────────────────────────────────┐   │
│  │ • SAST (Static Application Security Testing) - Semgrep                       │   │
│  │ • SCA (Software Composition Analysis) - Dependabot, Snyk                     │   │
│  │ • Container scanning - Trivy, ECR scanning, Inspector                        │   │
│  │ • DAST (Dynamic Application Security Testing) - OWASP ZAP (optional)         │   │
│  │ • Input validation (Pydantic)                                                │   │
│  │ • Security headers                                                           │   │
│  └─────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                      │
│  Layer 6: DETECTION & RESPONSE                                                       │
│  ┌─────────────────────────────────────────────────────────────────────────────┐   │
│  │ • GuardDuty (threat detection)                                               │   │
│  │ • Security Hub (centralized findings)                                        │   │
│  │ • CloudTrail (API audit logs)                                                │   │
│  │ • AWS Config (configuration compliance)                                      │   │
│  │ • CloudWatch Alarms (security metrics)                                       │   │
│  │ • Automated remediation (Lambda)                                             │   │
│  └─────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                      │
│  Layer 7: AUDIT & COMPLIANCE                                                         │
│  ┌─────────────────────────────────────────────────────────────────────────────┐   │
│  │ • CloudTrail logs (immutable, encrypted)                                     │   │
│  │ • Security Hub compliance standards                                          │   │
│  │ • Config conformance packs                                                   │   │
│  │ • Regular security assessments                                               │   │
│  │ • Incident response procedures                                               │   │
│  └─────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

## 5.2 IAM Security Design

### 5.2.1 Role Definitions

**ECS Task Execution Role:**
```
Purpose: Used by ECS agent to pull images and write logs

Trust Policy:
  Principal: ecs-tasks.amazonaws.com
  Condition: aws:SourceAccount equals your account ID

Permissions:
  - ecr:GetAuthorizationToken (all resources)
  - ecr:BatchCheckLayerAvailability (specific repo)
  - ecr:GetDownloadUrlForLayer (specific repo)
  - ecr:BatchGetImage (specific repo)
  - logs:CreateLogStream (specific log group)
  - logs:PutLogEvents (specific log group)
  - secretsmanager:GetSecretValue (specific secrets)
  - kms:Decrypt (specific key)
```

**ECS Task Role:**
```
Purpose: Used by the application at runtime

Trust Policy:
  Principal: ecs-tasks.amazonaws.com
  Condition: aws:SourceAccount equals your account ID

Permissions:
  - s3:GetObject (specific bucket/prefix)
  - s3:PutObject (specific bucket/prefix)
  - secretsmanager:GetSecretValue (specific secrets)
  - kms:Decrypt (specific key)
  - cloudwatch:PutMetricData (specific namespace)
```

**GitHub Actions Role:**
```
Purpose: CI/CD deployment from GitHub Actions

Trust Policy:
  Principal: token.actions.githubusercontent.com
  Condition:
    StringEquals:
      token.actions.githubusercontent.com:aud: sts.amazonaws.com
    StringLike:
      token.actions.githubusercontent.com:sub: repo:your-org/your-repo:*

Permissions:
  - ecr:GetAuthorizationToken
  - ecr:BatchCheckLayerAvailability
  - ecr:GetDownloadUrlForLayer
  - ecr:BatchGetImage
  - ecr:PutImage
  - ecr:InitiateLayerUpload
  - ecr:UploadLayerPart
  - ecr:CompleteLayerUpload
  - ecs:UpdateService (specific services)
  - ecs:DescribeServices (specific clusters)
  - ecs:DescribeTaskDefinition
  - ecs:RegisterTaskDefinition
  - iam:PassRole (specific task roles)
```

### 5.2.2 Security Boundaries

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                               IAM SECURITY BOUNDARIES                                │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│  ┌─────────────────────────────────────────────────────────────────────────────┐   │
│  │                         PRODUCTION ENVIRONMENT                               │   │
│  │                                                                              │   │
│  │  Resources can only be modified by:                                          │   │
│  │  • GitHub Actions role (with manual approval in workflow)                    │   │
│  │  • Break-glass admin role (requires MFA, logged in CloudTrail)              │   │
│  │                                                                              │   │
│  │  Explicit deny policies prevent:                                             │   │
│  │  • Deletion of production databases                                          │   │
│  │  • Modification of security groups to allow 0.0.0.0/0                       │   │
│  │  • Disabling of CloudTrail or GuardDuty                                     │   │
│  │  • Public access to S3 buckets                                              │   │
│  │                                                                              │   │
│  └─────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                      │
│  ┌─────────────────────────────────────────────────────────────────────────────┐   │
│  │                     STAGING/DEV ENVIRONMENTS                                 │   │
│  │                                                                              │   │
│  │  Resources can be modified by:                                               │   │
│  │  • GitHub Actions role (automatic deployment)                                │   │
│  │  • Developer roles (limited permissions)                                     │   │
│  │                                                                              │   │
│  │  Still protected:                                                            │   │
│  │  • Cannot access production resources                                        │   │
│  │  • Cannot disable security services                                          │   │
│  │  • All actions logged                                                        │   │
│  │                                                                              │   │
│  └─────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

## 5.3 Network Security Design

### 5.3.1 Security Group Rules Matrix

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                          SECURITY GROUP TRAFFIC MATRIX                               │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│  FROM \ TO        │ ALB SG │ App SG │ RDS SG │ Redis SG │ Endpoint SG │ Internet   │
│  ─────────────────┼────────┼────────┼────────┼──────────┼─────────────┼────────────│
│  Internet         │  443   │   ✗    │   ✗    │    ✗     │     ✗       │    N/A     │
│  ALB SG           │  N/A   │  8000  │   ✗    │    ✗     │     ✗       │     ✗      │
│  App SG           │   ✗    │  N/A   │  5432  │   6379   │    443      │  via NAT   │
│  RDS SG           │   ✗    │   ✗    │  N/A   │    ✗     │     ✗       │     ✗      │
│  Redis SG         │   ✗    │   ✗    │   ✗    │   N/A    │     ✗       │     ✗      │
│  Endpoint SG      │   ✗    │   ✗    │   ✗    │    ✗     │    N/A      │ AWS APIs   │
│                                                                                      │
│  Legend:                                                                             │
│  • Number = allowed port                                                             │
│  • ✗ = denied                                                                        │
│  • N/A = same security group or not applicable                                       │
│                                                                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

### 5.3.2 NACL Rules

**Public Subnet NACL:**
```
Inbound Rules:
  100: Allow HTTPS (443) from 0.0.0.0/0
  110: Allow HTTP (80) from 0.0.0.0/0
  120: Allow ephemeral ports (1024-65535) from 0.0.0.0/0  # Return traffic
  *: Deny all

Outbound Rules:
  100: Allow all traffic to 0.0.0.0/0
  *: Deny all
```

**Private Subnet NACL:**
```
Inbound Rules:
  100: Allow all traffic from 10.0.0.0/16  # VPC internal
  110: Allow ephemeral ports from 0.0.0.0/0  # Return traffic from internet
  *: Deny all

Outbound Rules:
  100: Allow all traffic to 10.0.0.0/16  # VPC internal
  110: Allow HTTPS to 0.0.0.0/0  # For NAT Gateway
  *: Deny all
```

**Data Subnet NACL:**
```
Inbound Rules:
  100: Allow PostgreSQL (5432) from 10.0.11.0/24, 10.0.12.0/24, 10.0.13.0/24
  110: Allow Redis (6379) from 10.0.11.0/24, 10.0.12.0/24, 10.0.13.0/24
  *: Deny all

Outbound Rules:
  100: Allow ephemeral ports to 10.0.11.0/24, 10.0.12.0/24, 10.0.13.0/24
  *: Deny all
```

## 5.4 Data Encryption Strategy

### 5.4.1 Encryption at Rest

| Resource | Encryption Method | Key Type |
|----------|-------------------|----------|
| RDS PostgreSQL | TDE | Customer Managed CMK |
| ElastiCache Redis | At-rest encryption | Customer Managed CMK |
| S3 Buckets | SSE-KMS | Customer Managed CMK |
| Secrets Manager | Default encryption | Customer Managed CMK |
| CloudWatch Logs | Default encryption | AWS Managed Key |
| EBS Volumes | Volume encryption | Customer Managed CMK |

### 5.4.2 Encryption in Transit

| Connection | Protocol | Minimum Version |
|------------|----------|-----------------|
| Client → ALB | HTTPS | TLS 1.2 |
| ALB → ECS | HTTP | (internal VPC) |
| ECS → RDS | SSL | TLS 1.2 |
| ECS → Redis | TLS | TLS 1.2 |
| ECS → AWS APIs | HTTPS | TLS 1.2 |

### 5.4.3 KMS Key Policy

```
Key Policy Structure:
  - Key administrators: DevOps team, Security team
  - Key users: ECS task roles, Lambda roles
  - Key deletion: Requires 30-day waiting period
  - Automatic rotation: Enabled (annual)
```

## 5.5 Secrets Management Strategy

### 5.5.1 Secret Hierarchy

```
Secrets Manager Structure:

/{environment}/
├── database/
│   └── credentials          # username, password, host, port, database
├── redis/
│   └── auth-token           # Redis AUTH password
├── app/
│   ├── jwt-secret           # JWT signing key
│   └── external-api-keys    # Third-party API keys
└── monitoring/
    └── slack-webhook        # Slack webhook URL
```

### 5.5.2 Secret Rotation

| Secret Type | Rotation Strategy | Frequency |
|-------------|-------------------|-----------|
| RDS credentials | Lambda rotation function | 30 days (prod), manual (dev/staging) |
| Redis auth token | Manual with rolling update | As needed |
| API keys | Manual | On compromise or employee departure |
| JWT secret | Manual with grace period | Annually or on compromise |

## 5.6 CI/CD Security

### 5.6.1 Pipeline Security Controls

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                              CI/CD SECURITY GATES                                    │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│  STAGE 1: CODE COMMIT                                                                │
│  ┌─────────────────────────────────────────────────────────────────────────────┐   │
│  │ • Branch protection rules (require PR, reviews)                              │   │
│  │ • Signed commits (optional)                                                  │   │
│  │ • No direct commits to main                                                  │   │
│  └─────────────────────────────────────────────────────────────────────────────┘   │
│                                      ↓                                               │
│  STAGE 2: STATIC ANALYSIS                                                            │
│  ┌─────────────────────────────────────────────────────────────────────────────┐   │
│  │ • SAST: Semgrep scans for security vulnerabilities                          │   │
│  │ • Linting: Ruff checks code quality                                          │   │
│  │ • Secrets scanning: Gitleaks/TruffleHog                                     │   │
│  │ • FAIL if: Critical vulnerabilities found                                    │   │
│  └─────────────────────────────────────────────────────────────────────────────┘   │
│                                      ↓                                               │
│  STAGE 3: BUILD & TEST                                                               │
│  ┌─────────────────────────────────────────────────────────────────────────────┐   │
│  │ • Unit tests with coverage requirements                                      │   │
│  │ • Integration tests                                                          │   │
│  │ • FAIL if: Tests fail or coverage < threshold                               │   │
│  └─────────────────────────────────────────────────────────────────────────────┘   │
│                                      ↓                                               │
│  STAGE 4: CONTAINER SECURITY                                                         │
│  ┌─────────────────────────────────────────────────────────────────────────────┐   │
│  │ • Trivy: Scan Docker image for vulnerabilities                              │   │
│  │ • ECR scan: Additional scanning on push                                      │   │
│  │ • Base image: Only approved base images                                      │   │
│  │ • FAIL if: High/Critical CVEs found                                         │   │
│  └─────────────────────────────────────────────────────────────────────────────┘   │
│                                      ↓                                               │
│  STAGE 5: INFRASTRUCTURE VALIDATION                                                  │
│  ┌─────────────────────────────────────────────────────────────────────────────┐   │
│  │ • Terraform plan review                                                      │   │
│  │ • Checkov/tfsec: IaC security scanning                                      │   │
│  │ • Cost estimation                                                            │   │
│  │ • FAIL if: Security misconfigurations detected                              │   │
│  └─────────────────────────────────────────────────────────────────────────────┘   │
│                                      ↓                                               │
│  STAGE 6: DEPLOYMENT                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────────┐   │
│  │ • Dev: Automatic deployment                                                  │   │
│  │ • Staging: Automatic after dev success                                       │   │
│  │ • Production: Manual approval required                                       │   │
│  │ • Deployment: Rolling update with health checks                              │   │
│  │ • Rollback: Automatic on health check failure                               │   │
│  └─────────────────────────────────────────────────────────────────────────────┘   │
│                                      ↓                                               │
│  STAGE 7: POST-DEPLOYMENT                                                            │
│  ┌─────────────────────────────────────────────────────────────────────────────┐   │
│  │ • DAST: OWASP ZAP scan (optional)                                           │   │
│  │ • Smoke tests: Verify critical endpoints                                     │   │
│  │ • Monitoring: Verify metrics are normal                                      │   │
│  └─────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

## 5.7 Threat Detection and Response

### 5.7.1 Detection Sources

| Source | What It Detects |
|--------|-----------------|
| GuardDuty | Compromised credentials, crypto mining, data exfiltration |
| CloudTrail | Unauthorized API calls, privilege escalation |
| VPC Flow Logs | Port scans, unusual traffic patterns |
| CloudWatch | Application errors, performance anomalies |
| AWS Config | Configuration drift, non-compliance |
| Security Hub | Aggregated findings, compliance scores |

### 5.7.2 Automated Response Actions

| Finding Type | Severity | Automated Response |
|--------------|----------|-------------------|
| Compromised EC2/ECS | High | Isolate network, alert |
| Unauthorized API call | Medium | Alert, log for review |
| Public S3 bucket | Critical | Revert to private, alert |
| Security group 0.0.0.0/0 | High | Revert change, alert |
| Root account usage | Critical | Alert immediately |

### 5.7.3 Incident Response Procedure

```
1. DETECTION
   └── GuardDuty/CloudWatch/Security Hub finding triggers alert

2. TRIAGE
   └── On-call engineer evaluates severity
   └── Critical: Immediate response
   └── High: Response within 1 hour
   └── Medium: Response within 4 hours

3. CONTAINMENT
   └── Isolate affected resources
   └── Preserve evidence (snapshots, logs)
   └── Enable enhanced logging

4. ERADICATION
   └── Remove threat actor access
   └── Patch vulnerabilities
   └── Rotate compromised credentials

5. RECOVERY
   └── Restore from clean backups
   └── Verify system integrity
   └── Re-enable services gradually

6. POST-INCIDENT
   └── Document timeline and actions
   └── Conduct root cause analysis
   └── Update runbooks and procedures
```

---

# 6. Repository Structure

```
cloud-platform-aws/
│
├── infrastructure/
│   │
│   ├── modules/                              # Reusable Terraform modules
│   │   │
│   │   ├── networking/
│   │   │   ├── vpc/                          # VPC with DNS settings
│   │   │   │   ├── main.tf
│   │   │   │   ├── variables.tf
│   │   │   │   ├── outputs.tf
│   │   │   │   └── README.md
│   │   │   ├── subnets/                      # Public, private, data subnets
│   │   │   ├── internet-gateway/             # IGW attachment
│   │   │   ├── nat-gateway/                  # NAT GW with EIP
│   │   │   ├── route-tables/                 # Route table associations
│   │   │   ├── security-groups/              # All security groups
│   │   │   ├── nacls/                        # Network ACLs
│   │   │   ├── vpc-endpoints/                # Interface and gateway endpoints
│   │   │   └── vpc-flow-logs/                # Flow logs to CloudWatch
│   │   │
│   │   ├── compute/
│   │   │   ├── ecs-cluster/                  # ECS cluster with Fargate
│   │   │   ├── ecs-service/                  # ECS service definition
│   │   │   ├── task-definition/              # Task definition with secrets
│   │   │   └── auto-scaling/                 # Application Auto Scaling
│   │   │
│   │   ├── load-balancing/
│   │   │   ├── alb/                          # Application Load Balancer
│   │   │   ├── target-group/                 # Target group with health check
│   │   │   └── listener/                     # HTTP and HTTPS listeners
│   │   │
│   │   ├── data/
│   │   │   ├── rds-postgres/                 # RDS PostgreSQL instance
│   │   │   ├── rds-subnet-group/             # DB subnet group
│   │   │   ├── rds-parameter-group/          # PostgreSQL parameters
│   │   │   ├── elasticache-redis/            # ElastiCache Redis cluster
│   │   │   ├── elasticache-subnet-group/     # Cache subnet group
│   │   │   └── elasticache-parameter-group/  # Redis parameters
│   │   │
│   │   ├── storage/
│   │   │   ├── s3-bucket/                    # S3 bucket with encryption
│   │   │   └── dynamodb-table/               # DynamoDB for state locking
│   │   │
│   │   ├── security/
│   │   │   ├── iam-roles/
│   │   │   │   ├── ecs-task-execution/       # ECS task execution role
│   │   │   │   ├── ecs-task/                 # ECS task role
│   │   │   │   ├── github-actions/           # CI/CD role with OIDC
│   │   │   │   ├── lambda-execution/         # Lambda execution role
│   │   │   │   └── rds-monitoring/           # RDS enhanced monitoring
│   │   │   ├── iam-policies/                 # Custom IAM policies
│   │   │   ├── kms/                          # KMS CMK for encryption
│   │   │   ├── secrets-manager/              # Secrets with rotation
│   │   │   ├── acm/                          # SSL certificate
│   │   │   ├── waf/                          # WAF Web ACL and rules
│   │   │   ├── guardduty/                    # GuardDuty detector
│   │   │   ├── security-hub/                 # Security Hub with standards
│   │   │   ├── cloudtrail/                   # CloudTrail trail
│   │   │   ├── aws-config/                   # Config rules
│   │   │   ├── access-analyzer/              # IAM Access Analyzer
│   │   │   └── inspector/                    # Inspector for ECR
│   │   │
│   │   ├── monitoring/
│   │   │   ├── cloudwatch-log-groups/        # Log groups with retention
│   │   │   ├── cloudwatch-alarms/            # Metric alarms
│   │   │   ├── cloudwatch-dashboard/         # Dashboard widgets
│   │   │   ├── sns-topics/                   # Alert topics
│   │   │   └── metric-filters/               # Log metric filters
│   │   │
│   │   ├── dns/
│   │   │   ├── route53-zone/                 # Hosted zone
│   │   │   └── route53-records/              # DNS records
│   │   │
│   │   └── automation/
│   │       ├── lambda-functions/
│   │       │   ├── scale-down-dev/           # Scale down dev environment
│   │       │   ├── scale-up-dev/             # Scale up dev environment
│   │       │   ├── slack-notifier/           # Send Slack alerts
│   │       │   └── auto-remediate/           # Security auto-remediation
│   │       └── eventbridge-rules/            # Scheduled rules
│   │
│   ├── environments/
│   │   ├── dev/
│   │   │   ├── main.tf                       # Module composition
│   │   │   ├── variables.tf                  # Input variables
│   │   │   ├── outputs.tf                    # Output values
│   │   │   ├── locals.tf                     # Local values
│   │   │   ├── providers.tf                  # Provider configuration
│   │   │   ├── backend.tf                    # S3 backend config
│   │   │   └── terraform.tfvars              # Environment values
│   │   ├── staging/
│   │   │   └── ... (same structure)
│   │   └── prod/
│   │       └── ... (same structure)
│   │
│   ├── global/                               # Shared resources
│   │   ├── ecr/                              # Container registry
│   │   ├── s3-terraform-state/               # State bucket and DynamoDB
│   │   ├── iam-github-oidc/                  # OIDC provider for GitHub
│   │   └── route53-zone/                     # Shared DNS zone
│   │
│   └── scripts/
│       ├── init-backend.sh                   # Initialize Terraform backend
│       ├── deploy.sh                         # Deploy to environment
│       ├── destroy.sh                        # Destroy environment
│       └── rotate-secrets.sh                 # Rotate secrets
│
├── application/
│   │
│   ├── src/
│   │   ├── app/
│   │   │   ├── __init__.py
│   │   │   ├── main.py                       # FastAPI application
│   │   │   ├── config.py                     # Configuration management
│   │   │   ├── models/
│   │   │   │   ├── __init__.py
│   │   │   │   ├── base.py                   # SQLAlchemy base
│   │   │   │   └── item.py                   # Item model
│   │   │   ├── routers/
│   │   │   │   ├── __init__.py
│   │   │   │   ├── health.py                 # Health check endpoints
│   │   │   │   └── items.py                  # Item CRUD endpoints
│   │   │   ├── services/
│   │   │   │   ├── __init__.py
│   │   │   │   ├── database.py               # Database connection
│   │   │   │   └── cache.py                  # Redis cache service
│   │   │   ├── middleware/
│   │   │   │   ├── __init__.py
│   │   │   │   ├── logging.py                # Request logging
│   │   │   │   └── security.py               # Security headers
│   │   │   └── utils/
│   │   │       ├── __init__.py
│   │   │       ├── secrets.py                # Fetch from Secrets Manager
│   │   │       └── logging.py                # Structured logging
│   │   ├── tests/
│   │   │   ├── __init__.py
│   │   │   ├── conftest.py                   # Pytest fixtures
│   │   │   ├── test_health.py
│   │   │   ├── test_items.py
│   │   │   └── test_integration.py
│   │   ├── alembic/                          # Database migrations
│   │   │   ├── versions/
│   │   │   ├── env.py
│   │   │   └── alembic.ini
│   │   ├── Dockerfile
│   │   ├── requirements.txt
│   │   ├── requirements-dev.txt
│   │   └── pyproject.toml
│   │
│   └── docker-compose.yml                    # Local development
│
├── .github/
│   └── workflows/
│       ├── ci.yml                            # Lint, test, security scan
│       ├── build-push.yml                    # Build and push to ECR
│       ├── deploy-dev.yml                    # Deploy to dev
│       ├── deploy-staging.yml                # Deploy to staging
│       ├── deploy-prod.yml                   # Deploy to prod (manual)
│       ├── terraform-plan.yml                # Plan on PR
│       ├── terraform-apply.yml               # Apply infrastructure
│       └── security-scan.yml                 # Scheduled security scan
│
├── docs/
│   ├── architecture/
│   │   ├── overview.md                       # Architecture overview
│   │   ├── networking.md                     # Network design
│   │   ├── security.md                       # Security architecture
│   │   ├── monitoring.md                     # Observability design
│   │   └── disaster-recovery.md              # DR procedures
│   ├── runbooks/
│   │   ├── deployment.md                     # Deployment procedures
│   │   ├── rollback.md                       # Rollback procedures
│   │   ├── incident-response.md              # Incident response
│   │   ├── database-operations.md            # DB backup/restore
│   │   └── secret-rotation.md                # Secret rotation
│   ├── decisions/
│   │   ├── ADR-001-vpc-design.md             # VPC design decision
│   │   ├── ADR-002-database-choice.md        # Database selection
│   │   ├── ADR-003-cicd-strategy.md          # CI/CD approach
│   │   ├── ADR-004-monitoring-strategy.md    # Monitoring approach
│   │   └── ADR-005-security-controls.md      # Security decisions
│   └── diagrams/
│       ├── architecture.png
│       ├── network-diagram.png
│       ├── security-layers.png
│       └── ci-cd-pipeline.png
│
├── scripts/
│   ├── setup-local-dev.sh                    # Set up local environment
│   ├── run-security-scan.sh                  # Run security tools locally
│   └── generate-diagrams.sh                  # Generate architecture diagrams
│
├── .gitignore
├── .pre-commit-config.yaml                   # Pre-commit hooks
├── Makefile                                  # Common commands
├── README.md                                 # Project documentation
├── CONTRIBUTING.md                           # Contribution guidelines
├── SECURITY.md                               # Security policy
└── COST_ESTIMATE.md                          # Cost breakdown
```

---

# 7. Implementation Phases

## Phase 1: Foundation Setup (Week 1)

### Objectives
- Set up Terraform remote state
- Create the base VPC networking
- Establish folder structure and conventions

### Tasks

**1.1 Repository Setup**
- Initialize Git repository
- Create folder structure as defined
- Set up .gitignore, pre-commit hooks
- Create README with project overview

**1.2 Terraform State Infrastructure**
- Create S3 bucket for Terraform state
  - Versioning enabled
  - Server-side encryption
  - Block public access
- Create DynamoDB table for state locking
  - Partition key: LockID
  - On-demand capacity

**1.3 VPC Module**
- Create VPC with specified CIDR
- Enable DNS hostnames and support
- Create Internet Gateway
- Output VPC ID, CIDR for other modules

**1.4 Subnet Module**
- Create public subnets (3 AZs)
- Create private subnets (3 AZs)
- Create data subnets (3 AZs)
- Output subnet IDs by type

**1.5 NAT Gateway Module**
- Create Elastic IP
- Create NAT Gateway in public subnet
- Configure for single NAT (dev) vs multi-NAT (prod)

**1.6 Route Tables**
- Create public route table with IGW route
- Create private route table with NAT route
- Create data route table (local only)
- Associate subnets with route tables

### Deliverables
- Working VPC with all subnets
- Resources deployed to dev environment
- Documentation of CIDR allocation

### Validation
```
- [ ] VPC created with correct CIDR
- [ ] All 9 subnets created across 3 AZs
- [ ] Internet Gateway attached
- [ ] NAT Gateway functional
- [ ] Route tables correctly associated
- [ ] Can launch test EC2 in private subnet with internet access
```

---

## Phase 2: Security Foundation (Week 2)

### Objectives
- Implement IAM roles with least privilege
- Set up encryption infrastructure
- Configure network security controls

### Tasks

**2.1 KMS Module**
- Create Customer Managed Key
- Configure key policy
- Enable automatic rotation
- Output key ARN and ID

**2.2 IAM Roles**
- Create ECS Task Execution Role
- Create ECS Task Role
- Create GitHub Actions OIDC provider and role
- Create Lambda Execution Role
- Document all permissions

**2.3 Security Groups**
- Create ALB security group
- Create Application security group
- Create RDS security group
- Create Redis security group
- Create VPC Endpoint security group
- Document all rules

**2.4 Network ACLs**
- Create public subnet NACL
- Create private subnet NACL
- Create data subnet NACL
- Associate with subnets

**2.5 VPC Endpoints**
- Create S3 gateway endpoint
- Create interface endpoints (ECR, Logs, Secrets, SSM, KMS, STS)
- Configure security groups

**2.6 VPC Flow Logs**
- Create CloudWatch log group
- Create IAM role for flow logs
- Enable flow logs on VPC

### Deliverables
- All IAM roles with documented permissions
- Security groups with documented rules
- KMS key for encryption
- VPC endpoints configured

### Validation
```
- [ ] IAM roles have minimal required permissions
- [ ] Security groups follow principle of least privilege
- [ ] KMS key created and accessible
- [ ] VPC endpoints functional
- [ ] Flow logs appearing in CloudWatch
```

---

## Phase 3: Data Layer (Week 3)

### Objectives
- Deploy PostgreSQL database
- Deploy Redis cache
- Configure secrets management

### Tasks

**3.1 Secrets Manager**
- Create database credentials secret
- Create Redis auth token secret
- Configure secret structure

**3.2 RDS Subnet Group**
- Create subnet group with data subnets
- Output subnet group name

**3.3 RDS Parameter Group**
- Create parameter group for PostgreSQL 15
- Configure recommended parameters
- Output parameter group name

**3.4 RDS PostgreSQL**
- Create RDS instance
- Configure Multi-AZ (prod only)
- Enable encryption with CMK
- Enable Performance Insights (staging/prod)
- Configure backup retention
- Set up deletion protection (prod)

**3.5 ElastiCache Subnet Group**
- Create subnet group with data subnets
- Output subnet group name

**3.6 ElastiCache Parameter Group**
- Create parameter group for Redis 7
- Configure recommended parameters

**3.7 ElastiCache Redis**
- Create Redis replication group
- Configure encryption at rest and in transit
- Set up automatic failover (prod)

### Deliverables
- RDS PostgreSQL running in each environment
- ElastiCache Redis running in each environment
- Secrets stored in Secrets Manager
- Database accessible from application subnets only

### Validation
```
- [ ] RDS instance accessible from private subnets
- [ ] RDS not accessible from public internet
- [ ] Redis accessible from private subnets
- [ ] Secrets retrievable with correct IAM role
- [ ] Encryption verified on all data stores
```

---

## Phase 4: Compute Layer (Week 4)

### Objectives
- Set up container registry
- Deploy ECS cluster and service
- Configure application load balancer

### Tasks

**4.1 ECR Repository**
- Create ECR repository
- Configure image scanning on push
- Set up lifecycle policy
- Output repository URL

**4.2 ACM Certificate**
- Request SSL certificate
- Configure DNS validation
- Output certificate ARN

**4.3 ALB Module**
- Create Application Load Balancer
- Configure in public subnets
- Enable access logging to S3

**4.4 Target Group**
- Create target group for ECS
- Configure health check (/health)
- Set deregistration delay

**4.5 ALB Listeners**
- Create HTTP listener (redirect to HTTPS)
- Create HTTPS listener with certificate
- Forward to target group

**4.6 ECS Cluster**
- Create ECS cluster
- Enable Container Insights
- Configure Fargate capacity providers

**4.7 Task Definition**
- Create task definition
- Configure container with environment variables
- Reference secrets from Secrets Manager
- Set up logging to CloudWatch
- Configure health check

**4.8 ECS Service**
- Create ECS service
- Configure desired count per environment
- Set up load balancer integration
- Configure deployment settings

**4.9 Auto Scaling**
- Create scaling target
- Create CPU-based scaling policy
- Create request count scaling policy (optional)

### Deliverables
- ECR repository with image
- ALB with HTTPS
- ECS service running FastAPI
- Auto-scaling configured

### Validation
```
- [ ] Docker image pushed to ECR
- [ ] ALB accessible via HTTPS
- [ ] Health check passing
- [ ] Application returns expected response
- [ ] Auto-scaling triggers on load
```

---

## Phase 5: Application Updates (Week 5)

### Objectives
- Update FastAPI application for database and cache
- Implement database migrations
- Add security middleware

### Tasks

**5.1 Application Configuration**
- Update config.py for environment variables
- Add Secrets Manager integration
- Configure logging

**5.2 Database Integration**
- Add SQLAlchemy async support
- Create database models
- Implement connection pooling
- Add database health check

**5.3 Redis Integration**
- Add redis-py client
- Implement cache service
- Add cache health check

**5.4 Database Migrations**
- Set up Alembic
- Create initial migration
- Document migration procedures

**5.5 Security Middleware**
- Add security headers middleware
- Add request logging middleware
- Implement rate limiting (optional)

**5.6 Health Endpoints**
- Update /health for dependencies
- Add /health/live (liveness)
- Add /health/ready (readiness)

**5.7 Testing**
- Update tests for new functionality
- Add integration tests
- Ensure coverage > 80%

### Deliverables
- FastAPI app with database integration
- Redis caching implemented
- Alembic migrations working
- All tests passing

### Validation
```
- [ ] Application connects to RDS
- [ ] Application connects to Redis
- [ ] Secrets fetched from Secrets Manager
- [ ] Database migrations run successfully
- [ ] All tests pass
```

---

## Phase 6: Monitoring & Alerting (Week 6)

### Objectives
- Set up CloudWatch dashboards
- Configure alarms and notifications
- Implement log analysis

### Tasks

**6.1 CloudWatch Log Groups**
- Create log groups for each service
- Configure retention periods
- Set up log encryption

**6.2 Metric Filters**
- Create filter for ERROR logs
- Create filter for latency extraction
- Create filter for request count

**6.3 SNS Topics**
- Create critical alerts topic
- Create warning alerts topic
- Configure subscriptions (email, Slack)

**6.4 CloudWatch Alarms**
- ALB 5xx errors alarm
- ALB high latency alarm
- ECS high CPU alarm
- ECS high memory alarm
- RDS high connections alarm
- RDS low storage alarm
- Redis high memory alarm

**6.5 CloudWatch Dashboard**
- Create dashboard per environment
- Add ALB metrics widgets
- Add ECS metrics widgets
- Add RDS metrics widgets
- Add Redis metrics widgets
- Add log insights widget

**6.6 Slack Integration (Lambda)**
- Create Lambda function for Slack notifications
- Configure SNS trigger
- Format messages for Slack

### Deliverables
- CloudWatch dashboard for each environment
- Alarms for all critical metrics
- Slack notifications working
- Log analysis queries documented

### Validation
```
- [ ] Dashboard shows all metrics
- [ ] Alarms trigger correctly
- [ ] SNS notifications sent
- [ ] Slack messages received
- [ ] Log Insights queries work
```

---

## Phase 7: Security Services (Week 7)

### Objectives
- Enable threat detection
- Set up compliance monitoring
- Implement automated security responses

### Tasks

**7.1 GuardDuty**
- Enable GuardDuty detector
- Configure finding publishing frequency
- Set up EventBridge integration

**7.2 Security Hub**
- Enable Security Hub
- Enable AWS Foundational Security Best Practices
- Enable CIS AWS Foundations Benchmark

**7.3 CloudTrail**
- Create trail for all regions
- Enable log file validation
- Configure S3 bucket for logs
- Enable CloudWatch Logs integration

**7.4 AWS Config**
- Enable AWS Config
- Create configuration recorder
- Create delivery channel
- Enable managed rules

**7.5 WAF**
- Create Web ACL
- Add AWS managed rule groups
- Add rate limiting rule
- Associate with ALB

**7.6 Access Analyzer**
- Create analyzer for account
- Configure findings notifications

**7.7 Inspector**
- Enable Inspector for ECR
- Configure scan on push
- Set up findings notifications

**7.8 Auto-Remediation Lambda**
- Create Lambda for security response
- Handle GuardDuty high-severity findings
- Implement isolation procedures

### Deliverables
- All security services enabled
- Findings flowing to Security Hub
- WAF protecting ALB
- Auto-remediation working

### Validation
```
- [ ] GuardDuty generating sample findings
- [ ] Security Hub showing compliance scores
- [ ] CloudTrail logging all API calls
- [ ] Config rules evaluating resources
- [ ] WAF blocking test malicious requests
```

---

## Phase 8: CI/CD Pipeline (Week 8)

### Objectives
- Implement GitHub Actions workflows
- Set up environment promotion
- Configure deployment automation

### Tasks

**8.1 GitHub OIDC Setup**
- Configure OIDC provider in AWS
- Create GitHub Actions IAM role
- Test role assumption

**8.2 CI Workflow**
- Lint with Ruff
- Run tests with pytest
- Security scan with Semgrep
- Secret scanning with Gitleaks

**8.3 Build Workflow**
- Build Docker image
- Scan with Trivy
- Push to ECR
- Tag with git SHA and latest

**8.4 Deploy Workflows**
- Create dev deploy workflow (automatic)
- Create staging deploy workflow (after dev)
- Create prod deploy workflow (manual approval)

**8.5 Terraform Workflows**
- Create plan workflow for PRs
- Create apply workflow for main branch
- Add cost estimation

**8.6 Scheduled Workflows**
- Weekly security scan
- Daily dependency check
- Terraform drift detection

**8.7 Branch Protection**
- Require PR reviews
- Require status checks
- Prevent direct pushes to main

### Deliverables
- All CI/CD workflows functional
- Automatic deployment to dev/staging
- Manual approval for production
- Infrastructure managed via PRs

### Validation
```
- [ ] CI passes on PR
- [ ] Image builds and pushes to ECR
- [ ] Dev deploys automatically
- [ ] Staging deploys after dev success
- [ ] Prod requires manual approval
- [ ] Terraform plans show in PR comments
```

---

## Phase 9: Automation & Cost Optimization (Week 9)

### Objectives
- Implement cost-saving automation
- Set up environment management
- Create operational runbooks

### Tasks

**9.1 Scale Down Lambda**
- Create Lambda to scale down dev
- Stop RDS instance
- Scale ECS to 0
- Schedule for 8 PM EST

**9.2 Scale Up Lambda**
- Create Lambda to scale up dev
- Start RDS instance
- Scale ECS to desired count
- Schedule for 8 AM EST

**9.3 Cost Allocation Tags**
- Tag all resources with Environment, Project, Owner
- Enable cost allocation tags in Billing
- Create cost reports

**9.4 Cost Anomaly Detection**
- Set up AWS Cost Anomaly Detection
- Configure alert thresholds
- Set up SNS notifications

**9.5 Operational Runbooks**
- Write deployment runbook
- Write rollback runbook
- Write incident response runbook
- Write database operations runbook

### Deliverables
- Dev environment auto-shutdown working
- Cost tracking implemented
- All runbooks documented
- Cost estimate document created

### Validation
```
- [ ] Dev scales down at 8 PM
- [ ] Dev scales up at 8 AM
- [ ] Cost allocation tags visible
- [ ] Anomaly detection configured
- [ ] Runbooks cover all scenarios
```

---

## Phase 10: Documentation & Polish (Week 10)

### Objectives
- Complete all documentation
- Create architecture diagrams
- Final testing and validation

### Tasks

**10.1 Architecture Documentation**
- Write architecture overview
- Document networking design
- Document security architecture
- Document monitoring strategy

**10.2 Architecture Diagrams**
- Create high-level architecture diagram
- Create network diagram
- Create security layers diagram
- Create CI/CD pipeline diagram

**10.3 ADRs (Architecture Decision Records)**
- ADR-001: VPC Design
- ADR-002: Database Choice
- ADR-003: CI/CD Strategy
- ADR-004: Monitoring Strategy
- ADR-005: Security Controls

**10.4 README Updates**
- Project overview
- Quick start guide
- Architecture summary
- Links to detailed docs

**10.5 Final Testing**
- End-to-end deployment test
- Disaster recovery test
- Security penetration test (basic)
- Load testing (basic)

**10.6 Cost Documentation**
- Document cost per environment
- Document cost optimization measures
- Create monthly cost forecast

### Deliverables
- Complete documentation
- All diagrams created
- ADRs for major decisions
- Project ready for portfolio

### Validation
```
- [ ] All documentation complete
- [ ] Diagrams accurate and clear
- [ ] ADRs explain decisions
- [ ] README provides clear overview
- [ ] Project deployable from scratch
```

---

# 8. Terraform Module Specifications

This section provides detailed specifications for each Terraform module.

## 8.1 VPC Module

**Path:** `infrastructure/modules/networking/vpc/`

**Purpose:** Create a VPC with DNS settings configured

**Inputs:**
| Variable | Type | Description | Default |
|----------|------|-------------|---------|
| vpc_cidr | string | CIDR block for VPC | - |
| environment | string | Environment name | - |
| enable_dns_hostnames | bool | Enable DNS hostnames | true |
| enable_dns_support | bool | Enable DNS support | true |
| tags | map(string) | Additional tags | {} |

**Outputs:**
| Output | Description |
|--------|-------------|
| vpc_id | ID of the created VPC |
| vpc_cidr | CIDR block of the VPC |
| vpc_arn | ARN of the VPC |

**Resources Created:**
- aws_vpc

---

## 8.2 Subnets Module

**Path:** `infrastructure/modules/networking/subnets/`

**Purpose:** Create public, private, and data subnets across availability zones

**Inputs:**
| Variable | Type | Description | Default |
|----------|------|-------------|---------|
| vpc_id | string | VPC ID | - |
| vpc_cidr | string | VPC CIDR for subnet calculation | - |
| environment | string | Environment name | - |
| availability_zones | list(string) | List of AZs | - |
| public_subnet_cidrs | list(string) | CIDRs for public subnets | - |
| private_subnet_cidrs | list(string) | CIDRs for private subnets | - |
| data_subnet_cidrs | list(string) | CIDRs for data subnets | - |
| tags | map(string) | Additional tags | {} |

**Outputs:**
| Output | Description |
|--------|-------------|
| public_subnet_ids | List of public subnet IDs |
| private_subnet_ids | List of private subnet IDs |
| data_subnet_ids | List of data subnet IDs |
| public_subnet_cidrs | List of public subnet CIDRs |
| private_subnet_cidrs | List of private subnet CIDRs |
| data_subnet_cidrs | List of data subnet CIDRs |

**Resources Created:**
- aws_subnet (9 total: 3 public, 3 private, 3 data)

---

## 8.3 Security Groups Module

**Path:** `infrastructure/modules/networking/security-groups/`

**Purpose:** Create all security groups with proper rules

**Inputs:**
| Variable | Type | Description | Default |
|----------|------|-------------|---------|
| vpc_id | string | VPC ID | - |
| environment | string | Environment name | - |
| app_port | number | Application port | 8000 |
| db_port | number | Database port | 5432 |
| redis_port | number | Redis port | 6379 |
| tags | map(string) | Additional tags | {} |

**Outputs:**
| Output | Description |
|--------|-------------|
| alb_security_group_id | ALB security group ID |
| app_security_group_id | Application security group ID |
| rds_security_group_id | RDS security group ID |
| redis_security_group_id | Redis security group ID |
| vpc_endpoint_security_group_id | VPC endpoint security group ID |

**Resources Created:**
- aws_security_group (5)
- aws_security_group_rule (multiple)

---

## 8.4 RDS PostgreSQL Module

**Path:** `infrastructure/modules/data/rds-postgres/`

**Purpose:** Create RDS PostgreSQL instance with security and backups

**Inputs:**
| Variable | Type | Description | Default |
|----------|------|-------------|---------|
| identifier | string | DB instance identifier | - |
| environment | string | Environment name | - |
| instance_class | string | Instance type | db.t3.micro |
| allocated_storage | number | Storage in GB | 20 |
| max_allocated_storage | number | Max storage for autoscaling | 100 |
| db_name | string | Database name | - |
| master_username | string | Master username | - |
| master_password | string | Master password | - |
| subnet_group_name | string | DB subnet group | - |
| security_group_ids | list(string) | Security group IDs | - |
| kms_key_arn | string | KMS key for encryption | - |
| multi_az | bool | Enable Multi-AZ | false |
| backup_retention_period | number | Backup retention days | 7 |
| deletion_protection | bool | Enable deletion protection | false |
| performance_insights | bool | Enable Performance Insights | false |
| tags | map(string) | Additional tags | {} |

**Outputs:**
| Output | Description |
|--------|-------------|
| endpoint | Database endpoint |
| port | Database port |
| arn | Database ARN |
| id | Database ID |

**Resources Created:**
- aws_db_instance
- random_password (for master password if not provided)

---

## 8.5 ECS Service Module

**Path:** `infrastructure/modules/compute/ecs-service/`

**Purpose:** Create ECS service with load balancer integration

**Inputs:**
| Variable | Type | Description | Default |
|----------|------|-------------|---------|
| service_name | string | Service name | - |
| cluster_arn | string | ECS cluster ARN | - |
| task_definition_arn | string | Task definition ARN | - |
| desired_count | number | Desired task count | 1 |
| subnet_ids | list(string) | Subnets for tasks | - |
| security_group_ids | list(string) | Security groups | - |
| target_group_arn | string | ALB target group ARN | - |
| container_name | string | Container name | - |
| container_port | number | Container port | 8000 |
| deployment_minimum_healthy_percent | number | Min healthy % | 50 |
| deployment_maximum_percent | number | Max % | 200 |
| health_check_grace_period | number | Health check grace | 60 |
| tags | map(string) | Additional tags | {} |

**Outputs:**
| Output | Description |
|--------|-------------|
| service_id | Service ID |
| service_name | Service name |
| service_arn | Service ARN |

**Resources Created:**
- aws_ecs_service

---

## 8.6 WAF Module

**Path:** `infrastructure/modules/security/waf/`

**Purpose:** Create WAF Web ACL with managed rules

**Inputs:**
| Variable | Type | Description | Default |
|----------|------|-------------|---------|
| name | string | Web ACL name | - |
| environment | string | Environment name | - |
| alb_arn | string | ALB ARN to associate | - |
| rate_limit | number | Requests per 5 min | 2000 |
| enable_sql_injection_rule | bool | Enable SQLi protection | true |
| enable_xss_rule | bool | Enable XSS protection | true |
| blocked_countries | list(string) | Countries to block | [] |
| tags | map(string) | Additional tags | {} |

**Outputs:**
| Output | Description |
|--------|-------------|
| web_acl_id | Web ACL ID |
| web_acl_arn | Web ACL ARN |

**Resources Created:**
- aws_wafv2_web_acl
- aws_wafv2_web_acl_association
- aws_wafv2_rule_group (if custom rules needed)

---

## 8.7 CloudWatch Alarms Module

**Path:** `infrastructure/modules/monitoring/cloudwatch-alarms/`

**Purpose:** Create CloudWatch alarms for critical metrics

**Inputs:**
| Variable | Type | Description | Default |
|----------|------|-------------|---------|
| environment | string | Environment name | - |
| alb_arn_suffix | string | ALB ARN suffix | - |
| target_group_arn_suffix | string | Target group ARN suffix | - |
| ecs_cluster_name | string | ECS cluster name | - |
| ecs_service_name | string | ECS service name | - |
| rds_instance_id | string | RDS instance ID | - |
| redis_cluster_id | string | Redis cluster ID | - |
| sns_topic_arn | string | SNS topic for alerts | - |
| thresholds | map(number) | Alarm thresholds | See defaults |
| tags | map(string) | Additional tags | {} |

**Outputs:**
| Output | Description |
|--------|-------------|
| alarm_arns | Map of alarm names to ARNs |

**Resources Created:**
- aws_cloudwatch_metric_alarm (multiple)

---

# 9. CI/CD Pipeline Design

## 9.1 Pipeline Overview

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                              CI/CD PIPELINE FLOW                                     │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│  ┌──────────────┐     ┌──────────────┐     ┌──────────────┐     ┌──────────────┐  │
│  │   Developer  │────▶│  Pull        │────▶│   CI         │────▶│   Build      │  │
│  │   Commits    │     │  Request     │     │   Checks     │     │   & Scan     │  │
│  └──────────────┘     └──────────────┘     └──────────────┘     └──────────────┘  │
│                                                                         │           │
│                                                                         ▼           │
│  ┌──────────────┐     ┌──────────────┐     ┌──────────────┐     ┌──────────────┐  │
│  │   Deploy     │◀────│   Deploy     │◀────│   Deploy     │◀────│   Push to    │  │
│  │   Prod       │     │   Staging    │     │   Dev        │     │   ECR        │  │
│  │ (Manual Gate)│     │  (Automatic) │     │  (Automatic) │     │              │  │
│  └──────────────┘     └──────────────┘     └──────────────┘     └──────────────┘  │
│                                                                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

## 9.2 Workflow Specifications

### 9.2.1 CI Workflow (ci.yml)

**Trigger:** Pull requests to main branch

**Jobs:**

1. **lint**
   - Runs: ubuntu-latest
   - Steps:
     - Checkout code
     - Setup Python 3.12
     - Install Ruff
     - Run `ruff check .`
     - Run `ruff format --check .`

2. **test**
   - Runs: ubuntu-latest
   - Services: PostgreSQL, Redis (for integration tests)
   - Steps:
     - Checkout code
     - Setup Python 3.12
     - Install dependencies
     - Run `pytest --cov=app --cov-report=xml`
     - Upload coverage to Codecov

3. **security-scan**
   - Runs: ubuntu-latest
   - Steps:
     - Checkout code
     - Run Semgrep with p/python rules
     - Run Gitleaks for secret detection
     - Upload SARIF to GitHub Security

4. **terraform-plan** (if infrastructure changed)
   - Runs: ubuntu-latest
   - Steps:
     - Checkout code
     - Setup Terraform
     - Configure AWS credentials (OIDC)
     - Run `terraform init`
     - Run `terraform plan`
     - Comment plan on PR

---

### 9.2.2 Build and Push Workflow (build-push.yml)

**Trigger:** Push to main branch (after CI passes)

**Jobs:**

1. **build-and-push**
   - Runs: ubuntu-latest
   - Steps:
     - Checkout code
     - Configure AWS credentials (OIDC)
     - Login to ECR
     - Set up Docker Buildx
     - Build Docker image
     - Run Trivy scan
     - Push to ECR with tags:
       - `${{ github.sha }}`
       - `latest`
     - Output image tag

---

### 9.2.3 Deploy Dev Workflow (deploy-dev.yml)

**Trigger:** Completion of build-push workflow

**Jobs:**

1. **deploy**
   - Environment: dev
   - Runs: ubuntu-latest
   - Steps:
     - Configure AWS credentials
     - Update ECS service with new task definition
     - Wait for service stability
     - Run smoke tests
     - Notify Slack on completion

---

### 9.2.4 Deploy Staging Workflow (deploy-staging.yml)

**Trigger:** Successful completion of deploy-dev

**Jobs:**

1. **deploy**
   - Environment: staging
   - Runs: ubuntu-latest
   - Steps:
     - Configure AWS credentials
     - Update ECS service
     - Wait for service stability
     - Run integration tests
     - Notify Slack on completion

---

### 9.2.5 Deploy Prod Workflow (deploy-prod.yml)

**Trigger:** Manual dispatch with environment approval

**Jobs:**

1. **deploy**
   - Environment: production (requires approval)
   - Runs: ubuntu-latest
   - Steps:
     - Configure AWS credentials
     - Update ECS service
     - Wait for service stability
     - Run smoke tests
     - Notify Slack on completion

---

### 9.2.6 Terraform Apply Workflow (terraform-apply.yml)

**Trigger:** Push to main with changes in infrastructure/

**Jobs:**

1. **apply-global**
   - If: changes in infrastructure/global/
   - Steps: Apply global resources

2. **apply-dev**
   - Needs: apply-global
   - If: changes in infrastructure/environments/dev/
   - Steps: Apply dev environment

3. **apply-staging**
   - Needs: apply-dev
   - If: changes in infrastructure/environments/staging/
   - Steps: Apply staging environment

4. **apply-prod**
   - Needs: apply-staging
   - If: changes in infrastructure/environments/prod/
   - Environment: production (requires approval)
   - Steps: Apply prod environment

---

# 10. Monitoring and Observability

## 10.1 Metrics to Monitor

### Application Metrics (ALB)

| Metric | Description | Alarm Threshold |
|--------|-------------|-----------------|
| RequestCount | Total requests | N/A (dashboard only) |
| TargetResponseTime | Response latency | p99 > 2s |
| HTTPCode_Target_2XX | Successful responses | N/A |
| HTTPCode_Target_4XX | Client errors | > 100/min |
| HTTPCode_Target_5XX | Server errors | > 10/min |
| HealthyHostCount | Healthy targets | < desired count |
| UnHealthyHostCount | Unhealthy targets | > 0 |

### Compute Metrics (ECS)

| Metric | Description | Alarm Threshold |
|--------|-------------|-----------------|
| CPUUtilization | CPU usage % | > 80% for 5 min |
| MemoryUtilization | Memory usage % | > 85% for 5 min |
| RunningTaskCount | Number of tasks | < minimum |

### Database Metrics (RDS)

| Metric | Description | Alarm Threshold |
|--------|-------------|-----------------|
| CPUUtilization | CPU usage % | > 80% for 10 min |
| DatabaseConnections | Active connections | > 80% of max |
| FreeStorageSpace | Available storage | < 5 GB |
| ReadLatency | Read I/O latency | > 20 ms |
| WriteLatency | Write I/O latency | > 20 ms |
| FreeableMemory | Available memory | < 500 MB |

### Cache Metrics (Redis)

| Metric | Description | Alarm Threshold |
|--------|-------------|-----------------|
| CPUUtilization | CPU usage % | > 80% |
| DatabaseMemoryUsagePercentage | Memory usage % | > 80% |
| CurrConnections | Current connections | > 1000 |
| CacheHitRate | Cache hit ratio | < 80% |
| ReplicationLag | Replica lag | > 1 second |

## 10.2 Dashboard Layout

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                            PRODUCTION DASHBOARD                                      │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│  ┌───────────────────────────────────────────────────────────────────────────────┐ │
│  │ REQUEST METRICS                                                                │ │
│  │ ┌──────────────────────┐ ┌──────────────────────┐ ┌──────────────────────┐   │ │
│  │ │ Request Rate         │ │ Latency (p50/p99)    │ │ Error Rate (5xx)     │   │ │
│  │ │ [Area Chart]         │ │ [Line Chart]         │ │ [Line Chart]         │   │ │
│  │ └──────────────────────┘ └──────────────────────┘ └──────────────────────┘   │ │
│  └───────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                      │
│  ┌───────────────────────────────────────────────────────────────────────────────┐ │
│  │ COMPUTE METRICS                                                                │ │
│  │ ┌──────────────────────┐ ┌──────────────────────┐ ┌──────────────────────┐   │ │
│  │ │ ECS CPU Utilization  │ │ ECS Memory Usage     │ │ Running Tasks        │   │ │
│  │ │ [Line Chart]         │ │ [Line Chart]         │ │ [Number Widget]      │   │ │
│  │ └──────────────────────┘ └──────────────────────┘ └──────────────────────┘   │ │
│  └───────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                      │
│  ┌───────────────────────────────────────────────────────────────────────────────┐ │
│  │ DATABASE METRICS                                                               │ │
│  │ ┌──────────────────────┐ ┌──────────────────────┐ ┌──────────────────────┐   │ │
│  │ │ RDS Connections      │ │ RDS CPU Utilization  │ │ RDS Storage          │   │ │
│  │ │ [Line Chart]         │ │ [Line Chart]         │ │ [Gauge Widget]       │   │ │
│  │ └──────────────────────┘ └──────────────────────┘ └──────────────────────┘   │ │
│  └───────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                      │
│  ┌───────────────────────────────────────────────────────────────────────────────┐ │
│  │ CACHE METRICS                                                                  │ │
│  │ ┌──────────────────────┐ ┌──────────────────────┐ ┌──────────────────────┐   │ │
│  │ │ Redis Hit/Miss Ratio │ │ Redis Memory Usage   │ │ Redis Connections    │   │ │
│  │ │ [Stacked Area]       │ │ [Line Chart]         │ │ [Number Widget]      │   │ │
│  │ └──────────────────────┘ └──────────────────────┘ └──────────────────────┘   │ │
│  └───────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                      │
│  ┌───────────────────────────────────────────────────────────────────────────────┐ │
│  │ RECENT ERRORS (Log Insights Widget)                                            │ │
│  │                                                                                 │ │
│  │ fields @timestamp, @message                                                    │ │
│  │ | filter @message like /ERROR/                                                 │ │
│  │ | sort @timestamp desc                                                         │ │
│  │ | limit 20                                                                     │ │
│  │                                                                                 │ │
│  └───────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

## 10.3 Log Insights Queries

**Error Analysis:**
```sql
fields @timestamp, @message
| filter @message like /ERROR/
| parse @message '"path": "*"' as endpoint
| stats count() as errors by endpoint
| sort errors desc
| limit 10
```

**Slow Requests:**
```sql
fields @timestamp, @message
| filter @message like /Request completed/
| parse @message 'duration=*ms' as duration
| filter duration > 1000
| stats count() as slow_requests, avg(duration) as avg_duration by bin(5m)
```

**Request Volume by Status:**
```sql
fields @timestamp, @message
| filter @message like /Request completed/
| parse @message 'status=*' as status
| stats count() as requests by status
```

---

# 11. Cost Management

## 11.1 Cost Breakdown by Environment

### Development (~$80-120/month)

| Service | Configuration | Monthly Cost |
|---------|---------------|--------------|
| ECS Fargate | 0.25 vCPU, 0.5GB, 1 task, 10 hrs/day | ~$10 |
| RDS PostgreSQL | db.t3.micro, 20GB, stopped nights | ~$15 |
| ElastiCache Redis | cache.t3.micro | ~$15 |
| NAT Gateway | 1 NAT, minimal traffic | ~$35 |
| ALB | 1 ALB, minimal LCU | ~$20 |
| CloudWatch | Logs and metrics | ~$5 |
| S3 | Minimal storage | ~$1 |
| Other | Secrets Manager, KMS, etc. | ~$5 |

### Staging (~$150-200/month)

| Service | Configuration | Monthly Cost |
|---------|---------------|--------------|
| ECS Fargate | 0.5 vCPU, 1GB, 2 tasks, 24/7 | ~$45 |
| RDS PostgreSQL | db.t3.small, 50GB | ~$40 |
| ElastiCache Redis | cache.t3.small | ~$30 |
| NAT Gateway | 1 NAT | ~$35 |
| ALB | 1 ALB | ~$20 |
| CloudWatch | Logs and metrics | ~$10 |
| Other | Various | ~$10 |

### Production (~$400-600/month)

| Service | Configuration | Monthly Cost |
|---------|---------------|--------------|
| ECS Fargate | 1 vCPU, 2GB, 3 tasks min, 24/7 | ~$130 |
| RDS PostgreSQL | db.t3.medium, Multi-AZ, 100GB | ~$120 |
| ElastiCache Redis | cache.t3.medium, with replica | ~$70 |
| NAT Gateway | 3 NAT (one per AZ) | ~$100 |
| ALB | 1 ALB | ~$25 |
| CloudWatch | Logs, metrics, dashboards | ~$20 |
| WAF | Web ACL + rules | ~$15 |
| Other | Security services, DNS, etc. | ~$20 |

## 11.2 Cost Optimization Strategies

**Implemented:**
1. Dev environment auto-shutdown (saves ~60% on dev)
2. Single NAT Gateway in non-prod (saves ~$70/month each)
3. VPC endpoints to reduce NAT traffic
4. Right-sized instances per environment
5. Spot instances for non-prod (if using EC2)

**Recommended for future:**
1. Reserved Instances for prod RDS (saves ~30%)
2. Savings Plans for Fargate (saves ~20%)
3. S3 Intelligent-Tiering for logs
4. Review and optimize CloudWatch log retention

---

# 12. Documentation Requirements

## 12.1 Architecture Decision Records (ADRs)

Each ADR should follow this format:

```markdown
# ADR-XXX: [Title]

## Status
[Proposed | Accepted | Deprecated | Superseded]

## Context
[What is the issue we're addressing?]

## Decision
[What is the decision we made?]

## Consequences
[What are the results of this decision?]

## Alternatives Considered
[What other options did we evaluate?]
```

**Required ADRs:**
1. ADR-001: VPC Design (separate VPCs per environment)
2. ADR-002: Database Choice (PostgreSQL on RDS)
3. ADR-003: CI/CD Strategy (GitHub Actions with OIDC)
4. ADR-004: Monitoring Strategy (CloudWatch-centric)
5. ADR-005: Security Controls (defense in depth)

## 12.2 Runbook Templates

Each runbook should include:

1. **Purpose** - What this runbook is for
2. **Prerequisites** - What access/tools are needed
3. **Procedure** - Step-by-step instructions
4. **Verification** - How to verify success
5. **Rollback** - How to undo if something goes wrong
6. **Escalation** - Who to contact if stuck

**Required Runbooks:**
1. Deployment Procedures
2. Rollback Procedures
3. Incident Response
4. Database Backup/Restore
5. Secret Rotation
6. Scaling Operations

---

# 13. Learning Outcomes

By completing this project, you will gain practical experience with:

## AWS Services (25+)
- Networking: VPC, Subnets, NAT Gateway, IGW, Route Tables, Security Groups, NACLs, VPC Endpoints
- Compute: ECS, Fargate, ECR, ALB
- Database: RDS PostgreSQL, ElastiCache Redis
- Security: IAM, KMS, Secrets Manager, WAF, Shield, GuardDuty, Security Hub, CloudTrail, Config, Access Analyzer, Inspector, ACM
- Monitoring: CloudWatch (Logs, Metrics, Alarms, Dashboards), SNS
- Automation: Lambda, EventBridge
- DNS: Route 53
- Storage: S3, DynamoDB

## DevOps Practices
- Infrastructure as Code with Terraform
- CI/CD pipeline design and implementation
- Container orchestration
- GitOps workflows
- Environment management (dev/staging/prod)

## Security (DevSecOps)
- Defense in depth architecture
- IAM least privilege design
- Network segmentation
- Encryption at rest and in transit
- Secrets management
- Security scanning (SAST, container scanning)
- Threat detection and response
- Compliance monitoring

## Operational Excellence
- Monitoring and alerting
- Log aggregation and analysis
- Incident response procedures
- Runbook creation
- Cost optimization

---

# 14. Interview Talking Points

When discussing this project in interviews, highlight:

## Architecture Decisions
- "I designed a multi-environment architecture with separate VPCs for isolation..."
- "I implemented defense in depth with multiple security layers..."
- "I chose ECS Fargate over EKS for this project because..."

## Security Focus
- "I implemented least privilege IAM with specific permissions per role..."
- "I set up automated threat detection with GuardDuty and response with Lambda..."
- "All data is encrypted at rest using customer-managed KMS keys..."

## Operational Maturity
- "I created comprehensive monitoring with CloudWatch dashboards and actionable alerts..."
- "I documented runbooks for common operational tasks..."
- "I implemented cost optimization including auto-shutdown for dev..."

## CI/CD Pipeline
- "I set up OIDC federation for GitHub Actions to avoid long-lived credentials..."
- "The pipeline includes security scanning at multiple stages..."
- "Production deployments require manual approval after staging validation..."

## Problem-Solving Examples
- "When I was designing the network, I had to balance cost with availability by using single NAT Gateway in dev..."
- "I reduced NAT Gateway costs by implementing VPC endpoints for AWS services..."
- "I automated dev environment shutdown to reduce costs by 60%..."

---

# Appendix A: Resource Naming Convention

All resources follow this naming pattern:

```
{project}-{environment}-{resource-type}-{identifier}
```

Examples:
- `cloudplatform-prod-vpc`
- `cloudplatform-prod-subnet-public-a`
- `cloudplatform-prod-sg-alb`
- `cloudplatform-prod-ecs-cluster`
- `cloudplatform-prod-rds-postgres`

Tags applied to all resources:
- `Project`: cloud-platform
- `Environment`: dev | staging | prod
- `ManagedBy`: terraform
- `Owner`: charith

---

# Appendix B: CIDR Allocation

```
Development:    10.0.0.0/16
  Public:       10.0.1.0/24, 10.0.2.0/24, 10.0.3.0/24
  Private:      10.0.11.0/24, 10.0.12.0/24, 10.0.13.0/24
  Data:         10.0.21.0/24, 10.0.22.0/24, 10.0.23.0/24

Staging:        10.1.0.0/16
  Public:       10.1.1.0/24, 10.1.2.0/24, 10.1.3.0/24
  Private:      10.1.11.0/24, 10.1.12.0/24, 10.1.13.0/24
  Data:         10.1.21.0/24, 10.1.22.0/24, 10.1.23.0/24

Production:     10.2.0.0/16
  Public:       10.2.1.0/24, 10.2.2.0/24, 10.2.3.0/24
  Private:      10.2.11.0/24, 10.2.12.0/24, 10.2.13.0/24
  Data:         10.2.21.0/24, 10.2.22.0/24, 10.2.23.0/24
```

---

# Appendix C: Port Reference

| Port | Protocol | Service |
|------|----------|---------|
| 80 | HTTP | ALB (redirect) |
| 443 | HTTPS | ALB |
| 8000 | HTTP | FastAPI |
| 5432 | TCP | PostgreSQL |
| 6379 | TCP | Redis |

---

**End of Document**

*Document Version: 1.0*
*Last Updated: January 2026*
