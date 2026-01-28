# =============================================================================
# PHASE 7: Security Services
# =============================================================================
# This phase creates additional security monitoring:
# - CloudTrail (API activity logging)
# - IAM Access Analyzer (external access detection)
#
# Deferred services (add later for portfolio demos):
# - GuardDuty (~$10/month)
# - Security Hub (~$5/month)
# - AWS Config (costs per rule evaluation)
# - WAF (~$6/month)
#
# Prerequisites: Phase 1-2 (VPC, KMS)
# Estimated Cost: ~$1/month (CloudTrail S3 storage)
# =============================================================================

# -----------------------------------------------------------------------------
# CloudTrail Module
# -----------------------------------------------------------------------------
# Creates an audit trail of all API activity:
# - S3 bucket for log storage (encrypted, versioned)
# - Trail for management events (API calls)
# - Log file validation enabled
# - 90-day log retention
#
# This is FREE for management events (data events cost extra)
module "cloudtrail" {
  count  = var.deploy_up_to_phase >= 7 ? 1 : 0
  source = "../../modules/cloudtrail"

  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region
  kms_key_arn  = module.kms[0].key_arn

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# Access Analyzer Module
# -----------------------------------------------------------------------------
# Creates an IAM Access Analyzer:
# - Automatically analyzes resource policies
# - Detects resources accessible from outside your account
# - Monitors: S3, IAM roles, KMS keys, Lambda, SQS, Secrets Manager
#
# This service is completely FREE!
module "access_analyzer" {
  count  = var.deploy_up_to_phase >= 7 ? 1 : 0
  source = "../../modules/access-analyzer"

  project_name = var.project_name
  environment  = var.environment

  tags = local.common_tags
}
