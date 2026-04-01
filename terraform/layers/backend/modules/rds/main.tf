locals {
  name_prefix = "${var.environment}-${var.app_id}"
}

# ── VPC ──────────────────────────────────────────────────────────────────────
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true # required for VPC interface endpoints
  tags                 = { Name = "${local.name_prefix}-vpc", Environment = var.environment }
}

# ── Private subnets (Lambda + RDS) ───────────────────────────────────────────
resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]
  tags              = { Name = "${local.name_prefix}-private-${count.index}", Environment = var.environment }
}

# ── Route table for private subnets ──────────────────────────────────────────
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${local.name_prefix}-private-rt" }
}

resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# ── DB subnet group ───────────────────────────────────────────────────────────
resource "aws_db_subnet_group" "rds" {
  name       = "${local.name_prefix}-rds-subnet-group"
  subnet_ids = aws_subnet.private[*].id
  tags       = { Environment = var.environment }
}

# ── Security groups ───────────────────────────────────────────────────────────
resource "aws_security_group" "lambda" {
  name        = "${local.name_prefix}-lambda-sg"
  description = "Lambda functions security group"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${local.name_prefix}-lambda-sg", Environment = var.environment }
}

resource "aws_security_group" "rds" {
  name        = "${local.name_prefix}-rds-sg"
  description = "RDS PostgreSQL security group"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda.id]
  }

  tags = { Name = "${local.name_prefix}-rds-sg", Environment = var.environment }
}

resource "aws_security_group" "vpc_endpoints" {
  name        = "${local.name_prefix}-vpce-sg"
  description = "VPC interface endpoints security group"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda.id]
  }

  tags = { Name = "${local.name_prefix}-vpce-sg", Environment = var.environment }
}

# ── RDS credentials (Secrets Manager) ────────────────────────────────────────
resource "random_password" "rds_password" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret" "rds_credentials" {
  name                    = "${var.environment}/${var.app_id}/rds-pgvector"
  description             = "RDS PostgreSQL credentials for pgvector"
  recovery_window_in_days = var.environment == "prod" ? 7 : 0
  tags                    = { Environment = var.environment }
}

resource "aws_secretsmanager_secret_version" "rds_credentials" {
  secret_id = aws_secretsmanager_secret.rds_credentials.id
  secret_string = jsonencode({
    username = "pgvector_admin"
    password = random_password.rds_password.result
    host     = aws_db_instance.pgvector.address
    port     = 5432
    dbname   = "pgvector"
  })
  depends_on = [aws_db_instance.pgvector]
}

# ── RDS PostgreSQL instance ───────────────────────────────────────────────────
resource "aws_db_instance" "pgvector" {
  identifier        = "${local.name_prefix}-pgvector"
  engine            = "postgres"
  engine_version    = "16.13"
  instance_class    = var.db_instance_class
  allocated_storage = var.db_allocated_storage
  storage_encrypted = true

  db_name  = "pgvector"
  username = "pgvector_admin"
  password = random_password.rds_password.result

  db_subnet_group_name   = aws_db_subnet_group.rds.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  multi_az            = var.environment == "prod" ? true : false
  skip_final_snapshot = var.environment != "prod"
  deletion_protection = var.environment == "prod"
  publicly_accessible = false

  backup_retention_period = var.environment == "prod" ? 7 : 1
  backup_window           = "03:00-04:00"
  maintenance_window      = "sun:04:00-sun:05:00"

  tags = { Name = "${local.name_prefix}-pgvector", Environment = var.environment }
}

# ── VPC Endpoints ─────────────────────────────────────────────────────────────

# S3 Gateway endpoint (free)
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id]
  tags              = { Name = "${local.name_prefix}-s3-endpoint" }
}

# DynamoDB Gateway endpoint (free)
resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.region}.dynamodb"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id]
  tags              = { Name = "${local.name_prefix}-dynamodb-endpoint" }
}

# Bedrock Runtime Interface endpoint
resource "aws_vpc_endpoint" "bedrock_runtime" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.region}.bedrock-runtime"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true
  tags                = { Name = "${local.name_prefix}-bedrock-endpoint" }
}

# Secrets Manager Interface endpoint
resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.region}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true
  tags                = { Name = "${local.name_prefix}-secretsmanager-endpoint" }
}

# Lambda Interface endpoint (allows VPC-based Lambdas to invoke other Lambdas)
resource "aws_vpc_endpoint" "lambda" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.region}.lambda"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true
  tags                = { Name = "${local.name_prefix}-lambda-endpoint" }
}

# SNS Interface endpoint
resource "aws_vpc_endpoint" "sns" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.region}.sns"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true
  tags                = { Name = "${local.name_prefix}-sns-endpoint" }
}