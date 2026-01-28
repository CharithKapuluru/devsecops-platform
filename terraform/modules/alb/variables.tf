variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "public_subnet_ids" {
  description = "IDs of public subnets"
  type        = list(string)
}

variable "security_group_id" {
  description = "ID of ALB security group"
  type        = string
}

variable "certificate_arn" {
  description = "ARN of ACM certificate (optional)"
  type        = string
  default     = ""
}

variable "health_check_path" {
  description = "Path for health checks"
  type        = string
  default     = "/health"
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}
