output "project_budget_id" {
  description = "ID of the project monthly budget"
  value       = aws_budgets_budget.monthly.id
}

output "project_budget_name" {
  description = "Name of the project monthly budget"
  value       = aws_budgets_budget.monthly.name
}

output "account_budget_id" {
  description = "ID of the account total budget"
  value       = aws_budgets_budget.account_total.id
}

output "account_budget_name" {
  description = "Name of the account total budget"
  value       = aws_budgets_budget.account_total.name
}
