# =============================================================================
# PHASE 3: Data Layer
# =============================================================================
# This phase creates the data storage infrastructure:
# - Secrets Manager (for database credentials and app secrets)
# - RDS PostgreSQL (managed relational database)
#
# Prerequisites: Phase 1 (VPC, Subnets), Phase 2 (KMS, Security Groups)
# Estimated Cost: $0-15/month (Free Tier eligible for db.t3.micro)
# =============================================================================

# -----------------------------------------------------------------------------
# Secrets Manager Module
# -----------------------------------------------------------------------------
# Creates and manages secrets:
# - Database credentials (username, password auto-generated)
# - Application secret key (for JWT tokens, etc.)
#
# Secrets are encrypted with the KMS key from Phase 2
module "secrets" {
  count  = var.deploy_up_to_phase >= 3 ? 1 : 0
  source = "../../modules/secrets"

  project_name = var.project_name
  environment  = var.environment
  kms_key_arn  = module.kms[0].key_arn

  db_username = var.db_username
  db_name     = var.db_name

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# RDS PostgreSQL Module
# -----------------------------------------------------------------------------
# Creates a managed PostgreSQL database:
# - db.t3.micro instance (Free Tier eligible)
# - Encrypted storage with KMS
# - Automated backups (7 days retention)
# - Deployed in data subnets (no public access)
# - Single-AZ for cost savings (Multi-AZ in production)
module "rds" {
  count  = var.deploy_up_to_phase >= 3 ? 1 : 0
  source = "../../modules/rds"

  project_name      = var.project_name
  environment       = var.environment
  vpc_id            = module.vpc[0].vpc_id
  subnet_ids        = module.subnets[0].data_subnet_ids
  security_group_id = module.security_groups[0].rds_sg_id
  kms_key_arn       = module.kms[0].key_arn

  db_name     = var.db_name
  db_username = var.db_username
  db_password = module.secrets[0].db_password

  instance_class    = var.rds_instance_class
  allocated_storage = var.rds_allocated_storage

  tags = local.common_tags
}
