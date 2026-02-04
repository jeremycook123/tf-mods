output "function_arn" {
  description = "ARN of the Lambda function."
  value       = aws_lambda_function.this.arn
}

output "function_name" {
  description = "Name of the Lambda function."
  value       = aws_lambda_function.this.function_name
}

output "role_arn" {
  description = "IAM role ARN used by the Lambda function."
  value       = var.role_arn != null ? var.role_arn : aws_iam_role.this.arn
}

output "log_group_name" {
  description = "CloudWatch log group name for the function."
  value       = aws_cloudwatch_log_group.this.name
}
