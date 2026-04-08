output "rds_secret_arn" {
  value = aws_secretsmanager_secret.rds_credentials.arn
}

output "rds_secret_name" {
  value = aws_secretsmanager_secret.rds_credentials.name
}

output "lambda_security_group_id" {
  value = aws_security_group.lambda.id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "rds_endpoint" {
  value = aws_db_instance.pgvector.address
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "db_instance_identifier" {
  value = aws_db_instance.pgvector.identifier
}