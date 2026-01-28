output "instance_id" {
  description = "ID of the RDS instance"
  value       = aws_db_instance.main.id
}

output "endpoint" {
  description = "Endpoint of the RDS instance"
  value       = aws_db_instance.main.endpoint
}

output "address" {
  description = "Address of the RDS instance"
  value       = aws_db_instance.main.address
}

output "port" {
  description = "Port of the RDS instance"
  value       = aws_db_instance.main.port
}

output "db_name" {
  description = "Name of the database"
  value       = aws_db_instance.main.db_name
}

output "arn" {
  description = "ARN of the RDS instance"
  value       = aws_db_instance.main.arn
}
