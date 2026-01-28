# =============================================================================
# PHASE 9: Automation & Cost Optimization
# =============================================================================
# This phase creates cost-saving automation:
# - Lambda Scheduler (auto scale down/up ECS and RDS)
# - AWS Budgets (cost alerts)
#
# Note: Phase 8 is CI/CD with GitHub Actions (no Terraform resources)
#
# Prerequisites: Phase 1-4 (VPC, Security, Data, Compute)
# Estimated Cost: ~$0/month (Lambda free tier, Budgets are free)
# Estimated Savings: ~40% of compute costs!
# =============================================================================

# -----------------------------------------------------------------------------
# Lambda Scheduler Module
# -----------------------------------------------------------------------------
# Creates automated scaling to save costs:
# - Scale DOWN at 6 PM EST (stop RDS, scale ECS to 0)
# - Scale UP at 8 AM EST (start RDS, scale ECS to 1)
#
# This saves ~40% of ECS and RDS costs!
# You can manually scale using: ./scripts/scale-up.sh or ./scripts/scale-down.sh
module "lambda_scheduler" {
  count  = var.deploy_up_to_phase >= 9 ? 1 : 0
  source = "../../modules/lambda-scheduler"

  project_name     = var.project_name
  environment      = var.environment
  aws_region       = var.aws_region
  ecs_cluster_arn  = module.ecs[0].cluster_arn
  ecs_service_name = module.ecs[0].service_name
  rds_instance_id  = module.rds[0].instance_id

  scale_up_schedule   = var.scale_up_schedule
  scale_down_schedule = var.scale_down_schedule

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# AWS Budgets Module
# -----------------------------------------------------------------------------
# Creates budget alerts:
# - Project budget: $50/month (alerts at 80% and 100%)
# - Account budget: $100/month (safety net)
# - Forecasted overspend alerts
#
# You'll receive email alerts when approaching budget limits
module "budgets" {
  count  = var.deploy_up_to_phase >= 9 ? 1 : 0
  source = "../../modules/budgets"

  project_name         = var.project_name
  environment          = var.environment
  budget_limit         = var.budget_limit
  account_budget_limit = var.account_budget_limit
  alert_emails         = [var.alert_email]

  tags = local.common_tags
}
