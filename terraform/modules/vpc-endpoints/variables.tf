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

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "private_subnet_ids" {
  description = "IDs of private subnets for interface endpoints"
  type        = list(string)
}

variable "private_route_table_id" {
  description = "ID of private route table for gateway endpoints"
  type        = string
}

variable "vpc_endpoint_sg_id" {
  description = "ID of security group for VPC endpoints"
  type        = string
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}
