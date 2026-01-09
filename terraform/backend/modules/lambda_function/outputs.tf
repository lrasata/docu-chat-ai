output "function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.lambda_function.id
}

output "function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.lambda_function.arn
}

