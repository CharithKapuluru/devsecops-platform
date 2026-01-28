# =============================================================================
# DevSecOps Platform - Dev Environment
# =============================================================================
# This configuration supports phase-by-phase deployment.
# Set the `deploy_up_to_phase` variable to control which phases are deployed.
#
# Phase 1: Foundation (VPC, Subnets, Route Tables)
# Phase 2: Security (KMS, IAM, Security Groups, VPC Endpoints)
# Phase 3: Data (Secrets Manager, RDS PostgreSQL)
# Phase 4: Compute (ECR, ALB, ECS Fargate)
# Phase 5: Application (No Terraform - app code only)
# Phase 6: Monitoring (CloudWatch Logs, Alarms, Dashboard)
# Phase 7: Security Services (CloudTrail, Access Analyzer)
# Phase 8: CI/CD (No Terraform - GitHub Actions only)
# Phase 9: Cost Optimization (Lambda Scheduler, AWS Budgets)
# Phase 10: Documentation (No Terraform - docs only)
# =============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }

  # Uncomment after running bootstrap
  # backend "s3" {
  #   bucket         = "devsecops-platform-terraform-state-ACCOUNT_ID"
  #   key            = "env/dev/terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "devsecops-platform-terraform-locks"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
