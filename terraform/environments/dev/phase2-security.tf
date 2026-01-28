# =============================================================================
# PHASE 2: Security Foundation
# =============================================================================
# This phase creates the security infrastructure:
# - KMS (Key Management Service) for encryption
# - IAM Roles (ECS execution, ECS task, GitHub Actions OIDC)
# - Security Groups (ALB, Application, RDS, VPC Endpoints)
# - VPC Endpoints (to access AWS services without NAT Gateway)
#
# Prerequisites: Phase 1 (VPC, Subnets)
# Estimated Cost: ~$8/month (VPC Endpoints + KMS)
# =============================================================================

# -----------------------------------------------------------------------------
# KMS Module
# -----------------------------------------------------------------------------
# Creates a Customer Managed Key (CMK) for encrypting:
# - RDS database
# - Secrets Manager secrets
# - CloudWatch Logs
# - S3 buckets
module "kms" {
  count  = var.deploy_up_to_phase >= 2 ? 1 : 0
  source = "../../modules/kms"

  project_name = var.project_name
  environment  = var.environment

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# IAM Module
# -----------------------------------------------------------------------------
# Creates IAM roles with least-privilege permissions:
# - ECS Task Execution Role: Allows ECS to pull images, get secrets
# - ECS Task Role: Permissions for the running application
# - GitHub Actions Role: OIDC-based role for CI/CD (no long-lived credentials)
module "iam" {
  count  = var.deploy_up_to_phase >= 2 ? 1 : 0
  source = "../../modules/iam"

  project_name        = var.project_name
  environment         = var.environment
  aws_account_id      = data.aws_caller_identity.current.account_id
  aws_region          = var.aws_region
  github_org          = var.github_org
  github_repo         = var.github_repo
  kms_key_arn         = module.kms[0].key_arn
  secrets_manager_arn = "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:${var.project_name}/${var.environment}/*"
  ecr_repository_arn  = var.deploy_up_to_phase >= 4 ? module.ecr[0].repository_arn : "arn:aws:ecr:${var.aws_region}:${data.aws_caller_identity.current.account_id}:repository/${var.project_name}-${var.environment}"

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# Security Groups Module
# -----------------------------------------------------------------------------
# Creates security groups to control network traffic:
# - ALB SG: Allows HTTP/HTTPS from internet
# - App SG: Allows traffic from ALB only
# - RDS SG: Allows PostgreSQL from App only
# - VPC Endpoints SG: Allows HTTPS from VPC
module "security_groups" {
  count  = var.deploy_up_to_phase >= 2 ? 1 : 0
  source = "../../modules/security-groups"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.vpc[0].vpc_id
  vpc_cidr     = module.vpc[0].vpc_cidr

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# VPC Endpoints Module
# -----------------------------------------------------------------------------
# Creates VPC Endpoints to access AWS services privately:
# - S3 Gateway Endpoint (FREE)
# - ECR API Interface Endpoint (for docker login)
# - ECR DKR Interface Endpoint (for docker pull)
# - CloudWatch Logs Interface Endpoint
# - Secrets Manager Interface Endpoint
#
# This replaces NAT Gateway and saves ~$35/month!
module "vpc_endpoints" {
  count  = var.deploy_up_to_phase >= 2 ? 1 : 0
  source = "../../modules/vpc-endpoints"

  project_name           = var.project_name
  environment            = var.environment
  vpc_id                 = module.vpc[0].vpc_id
  aws_region             = var.aws_region
  private_subnet_ids     = module.subnets[0].private_subnet_ids
  private_route_table_id = module.subnets[0].private_route_table_id
  vpc_endpoint_sg_id     = module.security_groups[0].vpc_endpoint_sg_id

  tags = local.common_tags
}
