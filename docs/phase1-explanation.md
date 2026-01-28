# Phase 1: Foundation Setup - Detailed Explanation

## Table of Contents
1. [Overview](#overview)
2. [What We're Building](#what-were-building)
3. [Concepts You Need to Understand](#concepts-you-need-to-understand)
4. [The Code Explained](#the-code-explained)
5. [Architecture Diagram](#architecture-diagram)
6. [Why These Specific Choices?](#why-these-specific-choices)
7. [Deployment Steps](#deployment-steps)
8. [Verification Checklist](#verification-checklist)
9. [Cost](#cost)
10. [What's Next](#whats-next)

---

## Overview

**Phase 1** creates the foundational networking infrastructure for your entire cloud platform. Think of it as laying the foundation and building the walls of a house before you can add rooms, furniture, and people.

**What we create:**
- 1 VPC (Virtual Private Cloud)
- 1 Internet Gateway
- 6 Subnets (across 2 Availability Zones)
- 3 Route Tables

**Estimated Cost:** $0/month (VPCs and subnets are free!)

**Time to Deploy:** ~2-3 minutes

---

## What We're Building

Before diving into the code, let's understand the real-world analogy:

| AWS Concept | Real-World Analogy |
|-------------|-------------------|
| **VPC** | Your own private building/campus |
| **Subnets** | Floors or sections within your building |
| **Internet Gateway** | The main entrance door to the outside world |
| **Route Tables** | Signs that direct traffic to the right place |
| **Availability Zone** | Different physical buildings in different locations |

### Why Do We Need This?

When you create resources in AWS (databases, servers, containers), they need to exist within a network. You could use AWS's default VPC, but:

1. **Security**: A custom VPC gives you complete control over who can access what
2. **Isolation**: Your resources are separated from other AWS customers
3. **Cost Control**: You control network topology and costs (e.g., no unnecessary NAT Gateways)
4. **Best Practice**: Every serious production system uses custom VPCs

---

## Concepts You Need to Understand

### 1. VPC (Virtual Private Cloud)

A VPC is your own isolated section of the AWS cloud. It's like having your own private data center, but in the cloud.

**Key Properties:**
- **CIDR Block**: The IP address range for your VPC (we use `10.0.0.0/16`)
- **Region-specific**: A VPC exists in one AWS region (us-east-1)
- **Free**: VPCs themselves cost nothing

**What is CIDR?**

CIDR (Classless Inter-Domain Routing) notation defines a range of IP addresses.

```
10.0.0.0/16 means:
- Base IP: 10.0.0.0
- /16: First 16 bits are fixed (10.0.x.x)
- Available IPs: 65,536 addresses (10.0.0.0 to 10.0.255.255)
```

Think of it like a phone number area code:
- `10.0` is your "area code" (fixed)
- `x.x` is the "local number" (you can use any value 0-255)

### 2. Subnets

A subnet is a smaller network within your VPC. Why subdivide?

1. **Security Layers**: Some things should be public (load balancers), others private (databases)
2. **High Availability**: Spread resources across multiple data centers
3. **Organization**: Keep different types of resources separate

**Our Subnet Design:**

| Subnet Type | Purpose | CIDR Blocks | Internet Access? |
|-------------|---------|-------------|------------------|
| **Public** | Load balancers, bastion hosts | 10.0.1.0/24, 10.0.2.0/24 | YES (via IGW) |
| **Private** | Application containers (ECS) | 10.0.11.0/24, 10.0.12.0/24 | Limited (via VPC Endpoints) |
| **Data** | Databases (RDS) | 10.0.21.0/24, 10.0.22.0/24 | NO (local only) |

**Why /24?**
- `/24` gives you 256 IP addresses per subnet (minus 5 reserved by AWS = 251 usable)
- This is plenty for a dev environment
- Each subnet is in a different Availability Zone for high availability

### 3. Availability Zones (AZs)

Availability Zones are physically separate data centers within an AWS region. They have:
- Independent power supplies
- Independent networking
- Independent cooling systems

**Why use multiple AZs?**

If one data center fails (fire, power outage, network issues), your application keeps running in the other one!

```
us-east-1 Region
├── us-east-1a (AZ 1) ──── Physically separate building
├── us-east-1b (AZ 2) ──── Another building miles away
├── us-east-1c (AZ 3) ──── Yet another building
└── ... more AZs
```

We use 2 AZs (not 3) to save costs while still having redundancy.

### 4. Internet Gateway (IGW)

An Internet Gateway is the door between your VPC and the public internet.

**Without IGW:** Your VPC is completely isolated (like a bunker)
**With IGW:** Resources in public subnets can reach the internet

**Important:** Just having an IGW isn't enough - you also need:
1. A route table entry pointing to the IGW
2. The subnet to be marked as "public"
3. Resources to have public IP addresses

### 5. Route Tables

Route tables are like a GPS that tells network traffic where to go.

**How routing works:**

```
Traffic from your ECS container wants to reach the internet (8.8.8.8)

Step 1: Look at route table
Step 2: Find matching route (0.0.0.0/0 = "anywhere")
Step 3: Send traffic to that destination (IGW or local)
```

**Our Route Tables:**

| Route Table | Routes | Used By |
|-------------|--------|---------|
| **Public RT** | 0.0.0.0/0 → IGW | Public subnets |
| **Private RT** | Local only (VPC Endpoints added in Phase 2) | Private subnets |
| **Data RT** | Local only | Data subnets |

---

## The Code Explained

### File Structure

```
terraform/
├── modules/
│   ├── vpc/
│   │   ├── main.tf       # VPC and Internet Gateway
│   │   ├── variables.tf  # Input variables
│   │   └── outputs.tf    # Values to share with other modules
│   └── subnets/
│       ├── main.tf       # Subnets and Route Tables
│       ├── variables.tf  # Input variables
│       └── outputs.tf    # Values to share with other modules
└── environments/
    └── dev/
        ├── main.tf               # Provider configuration
        ├── phase1-foundation.tf  # Calls VPC and Subnets modules
        ├── variables.tf          # Environment variables
        └── outputs.tf            # Environment outputs
```

### Understanding Terraform Modules

A **module** is a reusable piece of Terraform code. Think of it like a function in programming:

```hcl
# Instead of writing all the code directly...
resource "aws_vpc" "main" { ... }
resource "aws_subnet" "public1" { ... }
resource "aws_subnet" "public2" { ... }
# ... 20 more resources

# You call a module that contains all of it:
module "vpc" {
  source = "../../modules/vpc"
  # pass in variables
}
```

**Benefits:**
1. **Reusability**: Use the same module for dev, staging, prod
2. **Maintainability**: Fix a bug in one place, it's fixed everywhere
3. **Readability**: High-level view of what's being created

### VPC Module Code (`modules/vpc/main.tf`)

```hcl
# This data source gets the list of available AZs in the region
data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  # Take only the first 2 AZs (we don't need all 6)
  azs = slice(data.aws_availability_zones.available.names, 0, var.az_count)
}

# THE VPC ITSELF
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr          # 10.0.0.0/16
  enable_dns_hostnames = true                  # AWS assigns DNS names to instances
  enable_dns_support   = true                  # Enable DNS resolution

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-vpc"
  })
}

# INTERNET GATEWAY
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id    # Attach to our VPC

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-igw"
  })
}
```

**Line-by-line explanation:**

| Line | What it does |
|------|--------------|
| `data "aws_availability_zones"` | Asks AWS "what AZs are available in this region?" |
| `slice(..., 0, var.az_count)` | Takes the first 2 AZs from the list |
| `cidr_block = var.vpc_cidr` | Sets the IP range (10.0.0.0/16 = 65k IPs) |
| `enable_dns_hostnames = true` | EC2/ECS instances get DNS names like `ip-10-0-1-5.ec2.internal` |
| `enable_dns_support = true` | VPC can resolve DNS names |
| `tags = merge(...)` | Combines common tags with resource-specific Name tag |
| `aws_internet_gateway` | Creates the door to the internet |
| `vpc_id = aws_vpc.main.id` | Attaches the gateway to our VPC |

### Subnets Module Code (`modules/subnets/main.tf`)

```hcl
locals {
  # Calculate CIDR blocks for each subnet type
  # cidrsubnet(vpc_cidr, new_bits, net_num)
  # Example: cidrsubnet("10.0.0.0/16", 8, 1) = "10.0.1.0/24"

  public_subnets  = [for i, az in var.availability_zones : cidrsubnet(var.vpc_cidr, 8, i + 1)]
  # Results: ["10.0.1.0/24", "10.0.2.0/24"]

  private_subnets = [for i, az in var.availability_zones : cidrsubnet(var.vpc_cidr, 8, i + 11)]
  # Results: ["10.0.11.0/24", "10.0.12.0/24"]

  data_subnets    = [for i, az in var.availability_zones : cidrsubnet(var.vpc_cidr, 8, i + 21)]
  # Results: ["10.0.21.0/24", "10.0.22.0/24"]
}
```

**Understanding `cidrsubnet()`:**

```
cidrsubnet("10.0.0.0/16", 8, 1)
         ↓              ↓  ↓
    Base CIDR       Add bits  Subnet number

/16 + 8 = /24 (256 IPs per subnet)
Subnet 1 = 10.0.1.0/24
Subnet 11 = 10.0.11.0/24
Subnet 21 = 10.0.21.0/24
```

**Creating the actual subnets:**

```hcl
# PUBLIC SUBNETS
resource "aws_subnet" "public" {
  count = length(var.availability_zones)    # Create 2 subnets (one per AZ)

  vpc_id                  = var.vpc_id
  cidr_block              = local.public_subnets[count.index]    # 10.0.1.0/24 or 10.0.2.0/24
  availability_zone       = var.availability_zones[count.index]  # us-east-1a or us-east-1b
  map_public_ip_on_launch = true    # Instances get public IPs automatically

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-public-${var.availability_zones[count.index]}"
    Tier = "public"
  })
}
```

**Understanding `count`:**

```hcl
count = length(var.availability_zones)  # count = 2

# This creates:
# aws_subnet.public[0] → us-east-1a, 10.0.1.0/24
# aws_subnet.public[1] → us-east-1b, 10.0.2.0/24
```

**Route Tables and Associations:**

```hcl
# PUBLIC ROUTE TABLE
resource "aws_route_table" "public" {
  vpc_id = var.vpc_id
}

# Route: Send internet-bound traffic (0.0.0.0/0) to the Internet Gateway
resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"     # Match ANY destination
  gateway_id             = var.igw_id       # Send to Internet Gateway
}

# Associate the route table with the public subnets
resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}
```

**What does `0.0.0.0/0` mean?**

It means "any IP address" - essentially a default route. If traffic doesn't match any other route, it goes here.

### Private and Data Subnets

The private and data subnets are similar but with key differences:

```hcl
# PRIVATE SUBNETS (for application containers)
resource "aws_subnet" "private" {
  # ...
  map_public_ip_on_launch = false    # NO public IPs
}

# PRIVATE ROUTE TABLE
resource "aws_route_table" "private" {
  vpc_id = var.vpc_id
  # NO route to internet gateway!
  # VPC Endpoints will be added in Phase 2
}

# DATA SUBNETS (for databases)
resource "aws_subnet" "data" {
  # ...
  map_public_ip_on_launch = false    # NO public IPs
}

# DATA ROUTE TABLE
resource "aws_route_table" "data" {
  vpc_id = var.vpc_id
  # NO routes at all - only local VPC traffic
  # Databases should NEVER touch the internet
}
```

### Environment Configuration (`environments/dev/phase1-foundation.tf`)

```hcl
# This calls the VPC module
module "vpc" {
  count  = var.deploy_up_to_phase >= 1 ? 1 : 0    # Only create if Phase >= 1
  source = "../../modules/vpc"

  project_name = var.project_name    # "devsecops-platform"
  environment  = var.environment      # "dev"
  vpc_cidr     = var.vpc_cidr         # "10.0.0.0/16"
  az_count     = var.az_count         # 2

  tags = local.common_tags
}

# This calls the Subnets module
module "subnets" {
  count  = var.deploy_up_to_phase >= 1 ? 1 : 0
  source = "../../modules/subnets"

  project_name       = var.project_name
  environment        = var.environment
  vpc_id             = module.vpc[0].vpc_id           # Get VPC ID from vpc module
  vpc_cidr           = module.vpc[0].vpc_cidr
  igw_id             = module.vpc[0].igw_id           # Get IGW ID from vpc module
  availability_zones = module.vpc[0].azs

  tags = local.common_tags
}
```

**Understanding `count` for phase control:**

```hcl
count = var.deploy_up_to_phase >= 1 ? 1 : 0
```

This is a ternary expression:
- If `deploy_up_to_phase >= 1`, create 1 instance of the module
- Otherwise, create 0 (don't create it)

This allows us to deploy infrastructure phase by phase!

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                            AWS REGION (us-east-1)                           │
│                                                                             │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │                    VPC: 10.0.0.0/16                                   │  │
│  │                    Name: devsecops-platform-dev-vpc                   │  │
│  │                                                                       │  │
│  │  ┌─────────────────────────┐    ┌─────────────────────────┐          │  │
│  │  │   Availability Zone A   │    │   Availability Zone B   │          │  │
│  │  │      (us-east-1a)       │    │      (us-east-1b)       │          │  │
│  │  │                         │    │                         │          │  │
│  │  │  ┌───────────────────┐  │    │  ┌───────────────────┐  │          │  │
│  │  │  │  Public Subnet    │  │    │  │  Public Subnet    │  │          │  │
│  │  │  │  10.0.1.0/24      │  │    │  │  10.0.2.0/24      │  │          │  │
│  │  │  │  (ALB goes here)  │  │    │  │  (ALB goes here)  │  │          │  │
│  │  │  └───────────────────┘  │    │  └───────────────────┘  │          │  │
│  │  │                         │    │                         │          │  │
│  │  │  ┌───────────────────┐  │    │  ┌───────────────────┐  │          │  │
│  │  │  │  Private Subnet   │  │    │  │  Private Subnet   │  │          │  │
│  │  │  │  10.0.11.0/24     │  │    │  │  10.0.12.0/24     │  │          │  │
│  │  │  │  (ECS goes here)  │  │    │  │  (ECS goes here)  │  │          │  │
│  │  │  └───────────────────┘  │    │  └───────────────────┘  │          │  │
│  │  │                         │    │                         │          │  │
│  │  │  ┌───────────────────┐  │    │  ┌───────────────────┐  │          │  │
│  │  │  │   Data Subnet     │  │    │  │   Data Subnet     │  │          │  │
│  │  │  │  10.0.21.0/24     │  │    │  │  10.0.22.0/24     │  │          │  │
│  │  │  │  (RDS goes here)  │  │    │  │  (RDS goes here)  │  │          │  │
│  │  │  └───────────────────┘  │    │  └───────────────────┘  │          │  │
│  │  │                         │    │                         │          │  │
│  │  └─────────────────────────┘    └─────────────────────────┘          │  │
│  │                                                                       │  │
│  │                        ┌─────────────────────┐                        │  │
│  │                        │  Internet Gateway   │                        │  │
│  │                        │  (IGW)              │                        │  │
│  │                        └─────────┬───────────┘                        │  │
│  │                                  │                                    │  │
│  └──────────────────────────────────┼────────────────────────────────────┘  │
│                                     │                                       │
└─────────────────────────────────────┼───────────────────────────────────────┘
                                      │
                                      ▼
                              ┌───────────────┐
                              │   INTERNET    │
                              └───────────────┘
```

### Route Tables Diagram

```
PUBLIC ROUTE TABLE (attached to public subnets)
┌─────────────────────────────────────────────┐
│ Destination     │ Target                    │
├─────────────────┼───────────────────────────┤
│ 10.0.0.0/16     │ local (automatic)         │
│ 0.0.0.0/0       │ igw-xxxxxx (IGW)          │
└─────────────────────────────────────────────┘

PRIVATE ROUTE TABLE (attached to private subnets)
┌─────────────────────────────────────────────┐
│ Destination     │ Target                    │
├─────────────────┼───────────────────────────┤
│ 10.0.0.0/16     │ local (automatic)         │
│ (VPC Endpoints added in Phase 2)            │
└─────────────────────────────────────────────┘

DATA ROUTE TABLE (attached to data subnets)
┌─────────────────────────────────────────────┐
│ Destination     │ Target                    │
├─────────────────┼───────────────────────────┤
│ 10.0.0.0/16     │ local (automatic)         │
│ (No other routes - maximum isolation)       │
└─────────────────────────────────────────────┘
```

---

## Why These Specific Choices?

### 1. Why 10.0.0.0/16 for the VPC CIDR?

| Option | Why we chose/didn't choose |
|--------|---------------------------|
| **10.0.0.0/16** ✓ | Private IP range, 65k addresses, commonly used, easy to remember |
| 172.16.0.0/16 | Also valid, but less intuitive |
| 192.168.0.0/16 | Too small for large deployments |
| Public IPs | Never use public IPs for VPC CIDR! |

### 2. Why 2 Availability Zones (not 3)?

| AZs | Cost Impact | Redundancy |
|-----|-------------|------------|
| 1 AZ | Cheapest | No redundancy (single point of failure) |
| **2 AZs** ✓ | Balanced | Good redundancy for dev/learning |
| 3 AZs | Most expensive | Production-grade (unnecessary for dev) |

For a learning project with budget constraints, 2 AZs provides redundancy without unnecessary cost.

### 3. Why 3 Subnet Tiers (Public/Private/Data)?

This is the **3-tier architecture** pattern used in enterprise applications:

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   PUBLIC     │────▶│   PRIVATE    │────▶│    DATA      │
│   (ALB)      │     │   (App)      │     │   (DB)       │
│              │     │              │     │              │
│ Internet     │     │ No direct    │     │ No internet  │
│ accessible   │     │ internet     │     │ at all       │
└──────────────┘     └──────────────┘     └──────────────┘
```

**Security benefit:** Even if an attacker compromises the ALB, they can't directly access the database because it's in an isolated subnet with no route to the internet.

### 4. Why No NAT Gateway?

| Option | Cost | Use Case |
|--------|------|----------|
| NAT Gateway | ~$35/month + data transfer | Private subnets need to download from internet |
| **VPC Endpoints** ✓ | ~$7/month | Private subnets only need to access AWS services |

Our ECS containers only need to:
- Pull images from ECR
- Send logs to CloudWatch
- Get secrets from Secrets Manager

All of these are AWS services, so VPC Endpoints (added in Phase 2) are cheaper!

### 5. Why enable_dns_hostnames and enable_dns_support?

These settings allow:
- EC2/ECS instances to get DNS names (e.g., `ip-10-0-1-5.ec2.internal`)
- VPC to resolve AWS service endpoints
- Required for VPC Endpoints to work properly

---

## Deployment Steps

### Prerequisites

Before deploying, ensure you have:

1. **AWS CLI installed and configured:**
   ```bash
   aws --version   # Should show version 2.x
   aws sts get-caller-identity   # Should show your account ID
   ```

2. **Terraform installed:**
   ```bash
   terraform --version   # Should show version 1.5+
   ```

3. **terraform.tfvars file configured:**
   ```bash
   cd terraform/environments/dev
   cp example.tfvars terraform.tfvars
   # Edit terraform.tfvars with your values
   ```

### Step 1: Configure Your Variables

Edit `terraform/environments/dev/terraform.tfvars`:

```hcl
# Phase control - start with Phase 1
deploy_up_to_phase = 1

# Basic configuration
aws_region   = "us-east-1"
project_name = "devsecops-platform"
environment  = "dev"

# Required but not used in Phase 1 (can set any value)
github_org  = "your-github-username"
github_repo = "your-repo-name"
alert_email = "your-email@example.com"
```

### Step 2: Initialize Terraform

```bash
cd terraform/environments/dev
terraform init
```

Expected output:
```
Initializing modules...
- subnets in ../../modules/subnets
- vpc in ../../modules/vpc

Initializing the backend...

Initializing provider plugins...
- Finding hashicorp/aws versions matching "~> 5.0"...
- Installing hashicorp/aws v5.x.x...

Terraform has been successfully initialized!
```

### Step 3: Preview the Changes (Plan)

```bash
terraform plan
```

Review the output. You should see:
- 1 VPC
- 1 Internet Gateway
- 6 Subnets (2 public, 2 private, 2 data)
- 3 Route Tables
- 3 Routes
- 6 Route Table Associations

Total: ~16 resources to create

### Step 4: Apply the Changes

```bash
terraform apply
```

Type `yes` when prompted.

Expected output:
```
Apply complete! Resources: 16 added, 0 changed, 0 destroyed.

Outputs:

data_subnet_ids = [
  "subnet-0abc...",
  "subnet-0def...",
]
deployment_summary = {
  "deployed_up_to_phase" = 1
  "phase_1_foundation" = "DEPLOYED"
  "phase_2_security" = "NOT DEPLOYED"
  ...
}
private_subnet_ids = [...]
public_subnet_ids = [...]
vpc_id = "vpc-0123..."
```

---

## Verification Checklist

After deployment, verify in the AWS Console:

### VPC Console (https://console.aws.amazon.com/vpc/)

- [ ] **Your VPCs** → See `devsecops-platform-dev-vpc` with CIDR `10.0.0.0/16`
- [ ] **Subnets** → See 6 subnets:
  - `devsecops-platform-dev-public-us-east-1a` (10.0.1.0/24)
  - `devsecops-platform-dev-public-us-east-1b` (10.0.2.0/24)
  - `devsecops-platform-dev-private-us-east-1a` (10.0.11.0/24)
  - `devsecops-platform-dev-private-us-east-1b` (10.0.12.0/24)
  - `devsecops-platform-dev-data-us-east-1a` (10.0.21.0/24)
  - `devsecops-platform-dev-data-us-east-1b` (10.0.22.0/24)
- [ ] **Internet Gateways** → See `devsecops-platform-dev-igw` attached to your VPC
- [ ] **Route Tables** → See 3 route tables:
  - `devsecops-platform-dev-public-rt` (with route to IGW)
  - `devsecops-platform-dev-private-rt` (local only)
  - `devsecops-platform-dev-data-rt` (local only)

### Verify via CLI

```bash
# List VPCs
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=devsecops-platform-dev-vpc" \
  --query 'Vpcs[*].[VpcId,CidrBlock,State]' --output table

# List Subnets
aws ec2 describe-subnets --filters "Name=tag:Project,Values=devsecops-platform" \
  --query 'Subnets[*].[SubnetId,CidrBlock,AvailabilityZone,Tags[?Key==`Name`].Value|[0]]' \
  --output table

# List Route Tables
aws ec2 describe-route-tables --filters "Name=tag:Project,Values=devsecops-platform" \
  --query 'RouteTables[*].[RouteTableId,Tags[?Key==`Name`].Value|[0]]' --output table
```

---

## Cost

| Resource | Cost |
|----------|------|
| VPC | Free |
| Subnets | Free |
| Internet Gateway | Free |
| Route Tables | Free |
| **Total Phase 1** | **$0/month** |

VPCs and their basic networking components are completely free. You only start paying when you add:
- NAT Gateways (~$35/month)
- VPC Endpoints (~$7/month for Interface Endpoints)
- Data transfer

---

## What's Next

In **Phase 2: Security Foundation**, we'll add:

1. **KMS (Key Management Service)** - For encrypting databases, secrets, and logs
2. **IAM Roles** - For ECS tasks and GitHub Actions CI/CD
3. **Security Groups** - Firewall rules for each tier
4. **VPC Endpoints** - Private access to AWS services (ECR, CloudWatch, Secrets Manager)

The VPC Endpoints will give our private subnets the ability to access AWS services without needing a NAT Gateway, saving us ~$35/month!

---

## Troubleshooting

### Error: "No valid credential sources found"
```bash
# Configure AWS CLI
aws configure
# Enter your Access Key ID, Secret Access Key, Region (us-east-1)
```

### Error: "Error creating VPC: VpcLimitExceeded"
AWS has a default limit of 5 VPCs per region. Either:
1. Delete unused VPCs
2. Request a limit increase in the AWS Console

### Error: "Invalid CIDR block"
Make sure your CIDR block doesn't overlap with existing VPCs if you're peering VPCs.

---

## Summary

In Phase 1, you learned:

1. **VPC** = Your private network in AWS
2. **Subnets** = Subdivisions of your VPC for security layers
3. **Internet Gateway** = The door to the internet
4. **Route Tables** = Traffic directing rules
5. **Availability Zones** = Physical redundancy across data centers

You created 16 AWS resources that form the foundation for your entire platform, all at $0/month!
