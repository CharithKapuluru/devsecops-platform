output "db_credentials_arn" {
  description = "ARN of database credentials secret"
  value       = aws_secretsmanager_secret.db_credentials.arn
}

output "db_credentials_name" {
  description = "Name of database credentials secret"
  value       = aws_secretsmanager_secret.db_credentials.name
}

output "db_password" {
  description = "Generated database password"
  value       = random_password.db_password.result
  sensitive   = true
}

output "app_secret_arn" {
  description = "ARN of application secret"
  value       = aws_secretsmanager_secret.app_secret.arn
}

output "app_secret_name" {
  description = "Name of application secret"
  value       = aws_secretsmanager_secret.app_secret.name
}
