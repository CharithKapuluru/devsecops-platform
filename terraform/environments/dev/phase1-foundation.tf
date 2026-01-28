# =============================================================================
# PHASE 1: Foundation Setup
# =============================================================================
# This phase creates the foundational networking infrastructure:
# - VPC (Virtual Private Cloud)
# - Subnets (Public, Private, Data) across 2 Availability Zones
# - Internet Gateway
# - Route Tables
#
# Prerequisites: None (this is the first phase)
# Estimated Cost: $0/month (VPC and subnets are free)
# =============================================================================

# -----------------------------------------------------------------------------
# VPC Module
# -----------------------------------------------------------------------------
# Creates the Virtual Private Cloud - your isolated network in AWS
module "vpc" {
  count  = var.deploy_up_to_phase >= 1 ? 1 : 0
  source = "../../modules/vpc"

  project_name = var.project_name
  environment  = var.environment
  vpc_cidr     = var.vpc_cidr
  az_count     = var.az_count

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# Subnets Module
# -----------------------------------------------------------------------------
# Creates 6 subnets across 2 AZs:
# - 2 Public subnets (for ALB, NAT Gateway if needed)
# - 2 Private subnets (for ECS tasks/application)
# - 2 Data subnets (for RDS, ElastiCache)
module "subnets" {
  count  = var.deploy_up_to_phase >= 1 ? 1 : 0
  source = "../../modules/subnets"

  project_name       = var.project_name
  environment        = var.environment
  vpc_id             = module.vpc[0].vpc_id
  vpc_cidr           = module.vpc[0].vpc_cidr
  igw_id             = module.vpc[0].igw_id
  availability_zones = module.vpc[0].azs

  tags = local.common_tags
}
