# =============================================================================
# PHASE 4: Compute Layer
# =============================================================================
# This phase creates the compute infrastructure:
# - ECR (Elastic Container Registry) for Docker images
# - ALB (Application Load Balancer) for traffic distribution
# - ECS (Elastic Container Service) Fargate for running containers
#
# Prerequisites: Phase 1-3 (VPC, Security, Data)
# Estimated Cost: ~$18-25/month (ALB ~$16 + ECS Fargate ~$5-10)
# =============================================================================

# -----------------------------------------------------------------------------
# ECR Module
# -----------------------------------------------------------------------------
# Creates a container registry to store Docker images:
# - Image scanning on push (security vulnerability detection)
# - Lifecycle policy (keeps last 10 images to save storage)
# - Encrypted with KMS
module "ecr" {
  count  = var.deploy_up_to_phase >= 4 ? 1 : 0
  source = "../../modules/ecr"

  project_name = var.project_name
  environment  = var.environment
  kms_key_arn  = module.kms[0].key_arn

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# ALB Module
# -----------------------------------------------------------------------------
# Creates an Application Load Balancer:
# - Deployed in public subnets (internet-facing)
# - HTTP listener (port 80) - redirects to HTTPS if cert provided
# - HTTPS listener (port 443) - if ACM certificate provided
# - Health checks on /health endpoint
# - Target group for ECS tasks
module "alb" {
  count  = var.deploy_up_to_phase >= 4 ? 1 : 0
  source = "../../modules/alb"

  project_name      = var.project_name
  environment       = var.environment
  vpc_id            = module.vpc[0].vpc_id
  public_subnet_ids = module.subnets[0].public_subnet_ids
  security_group_id = module.security_groups[0].alb_sg_id
  certificate_arn   = var.certificate_arn

  health_check_path = "/health"

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# ECS Module
# -----------------------------------------------------------------------------
# Creates an ECS Fargate service:
# - Cluster with Container Insights disabled (cost saving)
# - Task Definition with:
#   - 0.25 vCPU, 512MB memory (minimal for dev)
#   - Database credentials from Secrets Manager
#   - CloudWatch Logs for container output
# - Service with:
#   - Desired count of 1 task
#   - Load balancer integration
#   - Deployed in private subnets
module "ecs" {
  count  = var.deploy_up_to_phase >= 4 ? 1 : 0
  source = "../../modules/ecs"

  project_name       = var.project_name
  environment        = var.environment
  aws_region         = var.aws_region
  vpc_id             = module.vpc[0].vpc_id
  private_subnet_ids = module.subnets[0].private_subnet_ids
  security_group_id  = module.security_groups[0].app_sg_id

  ecr_repository_url = module.ecr[0].repository_url
  execution_role_arn = module.iam[0].ecs_execution_role_arn
  task_role_arn      = module.iam[0].ecs_task_role_arn
  target_group_arn   = module.alb[0].target_group_arn
  db_secret_arn      = module.secrets[0].db_credentials_arn
  app_secret_arn     = module.secrets[0].app_secret_arn

  db_host = module.rds[0].address
  db_port = module.rds[0].port
  db_name = var.db_name

  container_cpu    = var.container_cpu
  container_memory = var.container_memory
  desired_count    = var.ecs_desired_count

  app_port = var.app_port

  tags = local.common_tags
}
