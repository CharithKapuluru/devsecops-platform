# =============================================================================
# PHASE 6: Monitoring & Alerting
# =============================================================================
# This phase creates the monitoring infrastructure:
# - CloudWatch Log Groups (for application logs)
# - CloudWatch Alarms (for alerting on issues)
# - CloudWatch Dashboard (for visualization)
# - SNS Topic (for alert notifications)
#
# Note: Phase 5 is application code (no Terraform resources)
#
# Prerequisites: Phase 1-4 (VPC, Security, Data, Compute)
# Estimated Cost: ~$2-5/month (CloudWatch logs + alarms)
# =============================================================================

# -----------------------------------------------------------------------------
# CloudWatch Module
# -----------------------------------------------------------------------------
# Creates monitoring and alerting infrastructure:
# - SNS Topic for email alerts
# - CloudWatch Alarms:
#   - ALB 5xx errors (application errors)
#   - ECS running tasks (service health)
#   - RDS CPU utilization (database health)
# - CloudWatch Dashboard with key metrics
module "cloudwatch" {
  count  = var.deploy_up_to_phase >= 6 ? 1 : 0
  source = "../../modules/cloudwatch"

  project_name       = var.project_name
  environment        = var.environment
  aws_region         = var.aws_region
  alb_arn_suffix     = module.alb[0].alb_arn_suffix
  ecs_cluster_name   = module.ecs[0].cluster_name
  ecs_service_name   = module.ecs[0].service_name
  rds_instance_id    = module.rds[0].instance_id
  alert_email        = var.alert_email
  log_retention_days = var.log_retention_days

  tags = local.common_tags
}
