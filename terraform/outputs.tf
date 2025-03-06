output "lambda_function_arn" {
  description = "The ARN of the Lambda function"
  value       = aws_lambda_function.linkedin_jobs_function.arn
}

output "dynamodb_table_name" {
  description = "The name of the DynamoDB table"
  value       = aws_dynamodb_table.linkedin_jobs_table.name
}

output "lambda_function_name" {
  description = "The name of the Lambda function"
  value       = aws_lambda_function.linkedin_jobs_function.function_name
}

output "cloudwatch_rule_name" {
  description = "The name of the CloudWatch event rule"
  value       = aws_cloudwatch_event_rule.daily_job_check.name
}