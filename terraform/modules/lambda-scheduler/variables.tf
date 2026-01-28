variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "ecs_cluster_arn" {
  description = "ARN of the ECS cluster"
  type        = string
}

variable "ecs_service_name" {
  description = "Name of the ECS service"
  type        = string
}

variable "rds_instance_id" {
  description = "ID of the RDS instance"
  type        = string
}

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

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}
