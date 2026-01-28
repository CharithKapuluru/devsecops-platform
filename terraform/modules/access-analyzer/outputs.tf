output "analyzer_arn" {
  description = "ARN of the Access Analyzer"
  value       = aws_accessanalyzer_analyzer.main.arn
}

output "analyzer_name" {
  description = "Name of the Access Analyzer"
  value       = aws_accessanalyzer_analyzer.main.analyzer_name
}

output "analyzer_id" {
  description = "ID of the Access Analyzer"
  value       = aws_accessanalyzer_analyzer.main.id
}
