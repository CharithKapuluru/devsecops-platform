output "lambda_function_arn" {
  description = "ARN of the scheduler Lambda function"
  value       = aws_lambda_function.scheduler.arn
}

output "lambda_function_name" {
  description = "Name of the scheduler Lambda function"
  value       = aws_lambda_function.scheduler.function_name
}

output "scale_up_rule_arn" {
  description = "ARN of the scale up EventBridge rule"
  value       = aws_cloudwatch_event_rule.scale_up.arn
}

output "scale_down_rule_arn" {
  description = "ARN of the scale down EventBridge rule"
  value       = aws_cloudwatch_event_rule.scale_down.arn
}
