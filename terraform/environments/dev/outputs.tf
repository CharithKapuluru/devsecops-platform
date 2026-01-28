# =============================================================================
# Outputs
# =============================================================================
# Outputs are conditional based on which phases are deployed.
# If a phase is not deployed, its outputs will be null.
# =============================================================================

# -----------------------------------------------------------------------------
# Phase 1: Foundation Outputs
# -----------------------------------------------------------------------------
output "vpc_id" {
  description = "ID of the VPC"
  value       = var.deploy_up_to_phase >= 1 ? module.vpc[0].vpc_id : null
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = var.deploy_up_to_phase >= 1 ? module.subnets[0].public_subnet_ids : null
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = var.deploy_up_to_phase >= 1 ? module.subnets[0].private_subnet_ids : null
}

output "data_subnet_ids" {
  description = "IDs of data subnets"
  value       = var.deploy_up_to_phase >= 1 ? module.subnets[0].data_subnet_ids : null
}

# -----------------------------------------------------------------------------
# Phase 2: Security Outputs
# -----------------------------------------------------------------------------
output "kms_key_arn" {
  description = "ARN of the KMS key"
  value       = var.deploy_up_to_phase >= 2 ? module.kms[0].key_arn : null
}

output "github_actions_role_arn" {
  description = "ARN of the GitHub Actions IAM role"
  value       = var.deploy_up_to_phase >= 2 ? module.iam[0].github_actions_role_arn : null
}

# -----------------------------------------------------------------------------
# Phase 3: Data Outputs
# -----------------------------------------------------------------------------
output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = var.deploy_up_to_phase >= 3 ? module.rds[0].endpoint : null
}

output "db_secret_arn" {
  description = "ARN of database credentials secret"
  value       = var.deploy_up_to_phase >= 3 ? module.secrets[0].db_credentials_arn : null
}

# -----------------------------------------------------------------------------
# Phase 4: Compute Outputs
# -----------------------------------------------------------------------------
output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = var.deploy_up_to_phase >= 4 ? module.ecr[0].repository_url : null
}

output "alb_dns_name" {
  description = "DNS name of the ALB"
  value       = var.deploy_up_to_phase >= 4 ? module.alb[0].dns_name : null
}

output "alb_zone_id" {
  description = "Zone ID of the ALB"
  value       = var.deploy_up_to_phase >= 4 ? module.alb[0].zone_id : null
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = var.deploy_up_to_phase >= 4 ? module.ecs[0].cluster_name : null
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = var.deploy_up_to_phase >= 4 ? module.ecs[0].service_name : null
}

# -----------------------------------------------------------------------------
# Phase 6: Monitoring Outputs
# -----------------------------------------------------------------------------
output "sns_topic_arn" {
  description = "ARN of the SNS alert topic"
  value       = var.deploy_up_to_phase >= 6 ? module.cloudwatch[0].sns_topic_arn : null
}

output "dashboard_url" {
  description = "URL of the CloudWatch dashboard"
  value       = var.deploy_up_to_phase >= 6 ? module.cloudwatch[0].dashboard_url : null
}

# -----------------------------------------------------------------------------
# Phase 7: Security Services Outputs
# -----------------------------------------------------------------------------
output "cloudtrail_arn" {
  description = "ARN of the CloudTrail"
  value       = var.deploy_up_to_phase >= 7 ? module.cloudtrail[0].trail_arn : null
}

output "access_analyzer_arn" {
  description = "ARN of the Access Analyzer"
  value       = var.deploy_up_to_phase >= 7 ? module.access_analyzer[0].analyzer_arn : null
}

# -----------------------------------------------------------------------------
# Phase 9: Cost Optimization Outputs
# -----------------------------------------------------------------------------
output "scheduler_lambda_arn" {
  description = "ARN of the scheduler Lambda function"
  value       = var.deploy_up_to_phase >= 9 ? module.lambda_scheduler[0].lambda_function_arn : null
}

output "project_budget_name" {
  description = "Name of the project budget"
  value       = var.deploy_up_to_phase >= 9 ? module.budgets[0].project_budget_name : null
}

# -----------------------------------------------------------------------------
# Summary Output
# -----------------------------------------------------------------------------
output "deployment_summary" {
  description = "Summary of deployed phases"
  value = {
    deployed_up_to_phase = var.deploy_up_to_phase
    phase_1_foundation   = var.deploy_up_to_phase >= 1 ? "DEPLOYED" : "NOT DEPLOYED"
    phase_2_security     = var.deploy_up_to_phase >= 2 ? "DEPLOYED" : "NOT DEPLOYED"
    phase_3_data         = var.deploy_up_to_phase >= 3 ? "DEPLOYED" : "NOT DEPLOYED"
    phase_4_compute      = var.deploy_up_to_phase >= 4 ? "DEPLOYED" : "NOT DEPLOYED"
    phase_5_application  = "NO TERRAFORM (app code only)"
    phase_6_monitoring   = var.deploy_up_to_phase >= 6 ? "DEPLOYED" : "NOT DEPLOYED"
    phase_7_security_svc = var.deploy_up_to_phase >= 7 ? "DEPLOYED" : "NOT DEPLOYED"
    phase_8_cicd         = "NO TERRAFORM (GitHub Actions only)"
    phase_9_cost_opt     = var.deploy_up_to_phase >= 9 ? "DEPLOYED" : "NOT DEPLOYED"
    phase_10_docs        = "NO TERRAFORM (documentation only)"
  }
}
