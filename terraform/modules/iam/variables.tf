variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "aws_account_id" {
  description = "AWS Account ID"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "github_org" {
  description = "GitHub organization or username"
  type        = string
  default     = ""
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
  default     = ""
}

variable "kms_key_arn" {
  description = "ARN of the KMS key"
  type        = string
}

variable "secrets_manager_arn" {
  description = "ARN pattern for Secrets Manager secrets"
  type        = string
}

variable "ecr_repository_arn" {
  description = "ARN of ECR repository"
  type        = string
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}
