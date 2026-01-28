output "s3_endpoint_id" {
  description = "ID of S3 VPC endpoint"
  value       = aws_vpc_endpoint.s3.id
}

output "ecr_api_endpoint_id" {
  description = "ID of ECR API VPC endpoint"
  value       = aws_vpc_endpoint.ecr_api.id
}

output "ecr_dkr_endpoint_id" {
  description = "ID of ECR DKR VPC endpoint"
  value       = aws_vpc_endpoint.ecr_dkr.id
}

output "logs_endpoint_id" {
  description = "ID of CloudWatch Logs VPC endpoint"
  value       = aws_vpc_endpoint.logs.id
}

output "secretsmanager_endpoint_id" {
  description = "ID of Secrets Manager VPC endpoint"
  value       = aws_vpc_endpoint.secretsmanager.id
}
