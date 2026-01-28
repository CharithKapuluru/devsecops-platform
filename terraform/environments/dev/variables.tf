# =============================================================================
# Phase Control Variable
# =============================================================================
# Set this to control which phases are deployed:
# - Phase 1: Foundation (VPC, Subnets)
# - Phase 2: Security (KMS, IAM, Security Groups, VPC Endpoints)
# - Phase 3: Data (Secrets Manager, RDS)
# - Phase 4: Compute (ECR, ALB, ECS)
# - Phase 5: Application (no Terraform - app code only)
# - Phase 6: Monitoring (CloudWatch)
# - Phase 7: Security Services (CloudTrail, Access Analyzer)
# - Phase 8: CI/CD (no Terraform - GitHub Actions only)
# - Phase 9: Cost Optimization (Lambda Scheduler, Budgets)
# - Phase 10: Documentation (no Terraform - docs only)
# =============================================================================
variable "deploy_up_to_phase" {
  description = "Deploy infrastructure up to this phase (1-9). Each phase includes all previous phases."
  type        = number
  default     = 1

  validation {
    condition     = var.deploy_up_to_phase >= 1 && var.deploy_up_to_phase <= 9
    error_message = "deploy_up_to_phase must be between 1 and 9."
  }
}

# =============================================================================
# General Configuration
# =============================================================================
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "devsecops-platform"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

# VPC Configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "az_count" {
  description = "Number of availability zones"
  type        = number
  default     = 2
}

# GitHub Configuration (for OIDC)
variable "github_org" {
  description = "GitHub organization or username"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
}

# Database Configuration
variable "db_name" {
  description = "Name of the database"
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "dbadmin"
}

variable "rds_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "rds_allocated_storage" {
  description = "RDS allocated storage in GB"
  type        = number
  default     = 20
}

# ECS Configuration
variable "container_cpu" {
  description = "CPU units for container (256 = 0.25 vCPU)"
  type        = number
  default     = 256
}

variable "container_memory" {
  description = "Memory for container in MB"
  type        = number
  default     = 512
}

variable "ecs_desired_count" {
  description = "Desired number of ECS tasks"
  type        = number
  default     = 1
}

variable "app_port" {
  description = "Application port"
  type        = number
  default     = 8000
}

# SSL Certificate
variable "certificate_arn" {
  description = "ARN of ACM certificate for HTTPS (optional - will use HTTP if not provided)"
  type        = string
  default     = ""
}

# Monitoring
variable "alert_email" {
  description = "Email address for alerts"
  type        = string
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}

# Cost Optimization - Scheduler
variable "scale_up_schedule" {
  description = "Cron expression for scaling up (UTC)"
  type        = string
  default     = "cron(0 13 ? * MON-FRI *)" # 8 AM EST
}

variable "scale_down_schedule" {
  description = "Cron expression for scaling down (UTC)"
  type        = string
  default     = "cron(0 23 ? * MON-FRI *)" # 6 PM EST
}

# Cost Optimization - Budgets
variable "budget_limit" {
  description = "Monthly budget limit in USD for this project"
  type        = string
  default     = "50"
}

variable "account_budget_limit" {
  description = "Monthly budget limit in USD for entire AWS account"
  type        = string
  default     = "100"
}
