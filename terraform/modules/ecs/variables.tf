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

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "private_subnet_ids" {
  description = "IDs of private subnets"
  type        = list(string)
}

variable "security_group_id" {
  description = "ID of application security group"
  type        = string
}

variable "ecr_repository_url" {
  description = "URL of ECR repository"
  type        = string
}

variable "execution_role_arn" {
  description = "ARN of ECS task execution role"
  type        = string
}

variable "task_role_arn" {
  description = "ARN of ECS task role"
  type        = string
}

variable "target_group_arn" {
  description = "ARN of ALB target group"
  type        = string
}

variable "db_secret_arn" {
  description = "ARN of database credentials secret"
  type        = string
}

variable "app_secret_arn" {
  description = "ARN of application secret"
  type        = string
}

variable "db_host" {
  description = "Database host"
  type        = string
}

variable "db_port" {
  description = "Database port"
  type        = number
  default     = 5432
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "container_cpu" {
  description = "CPU units for container"
  type        = number
  default     = 256
}

variable "container_memory" {
  description = "Memory for container in MB"
  type        = number
  default     = 512
}

variable "desired_count" {
  description = "Desired number of tasks"
  type        = number
  default     = 1
}

variable "app_port" {
  description = "Application port"
  type        = number
  default     = 8000
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}
