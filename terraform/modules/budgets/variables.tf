variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "budget_limit" {
  description = "Monthly budget limit in USD for this project"
  type        = string
  default     = "50"
}

variable "account_budget_limit" {
  description = "Monthly budget limit in USD for entire account"
  type        = string
  default     = "100"
}

variable "alert_emails" {
  description = "List of email addresses to receive budget alerts"
  type        = list(string)
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}
