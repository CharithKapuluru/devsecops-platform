# Access Analyzer Module - IAM Access Analyzer (FREE)

# IAM Access Analyzer
resource "aws_accessanalyzer_analyzer" "main" {
  analyzer_name = "${var.project_name}-${var.environment}-analyzer"
  type          = "ACCOUNT" # Analyzes resources within this account

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-analyzer"
  })
}

# Note: Access Analyzer automatically generates findings when it detects:
# - S3 buckets accessible from outside your account
# - IAM roles that can be assumed by external entities
# - KMS keys that can be accessed externally
# - Lambda functions with public access
# - SQS queues accessible externally
# - Secrets Manager secrets with external access
