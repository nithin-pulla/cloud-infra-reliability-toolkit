terraform {
  required_version = ">= 1.5"
}

provider "aws" {
  region = var.region
}

locals {
  name   = "reliability-toolkit-dev"
  region = var.region
  
  vpc_cidr = "10.0.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)

  tags = {
    Environment = "dev"
    Project     = "reliability-toolkit"
    Terraform   = "true"
  }
}

data "aws_availability_zones" "available" {}

# Network (VPC)
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = local.name
  cidr = local.vpc_cidr

  azs             = local.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 4)]
  database_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 8)]

  enable_nat_gateway = true
  single_nat_gateway = true # Save costs in dev
  
  create_database_subnet_group = true

  tags = local.tags
}

# Observability
module "observability" {
  source = "../../modules/observability"

  app_name = local.name
  tags     = local.tags
}

# Database
module "aurora" {
  source = "../../modules/aurora-postgres"

  cluster_name           = "${local.name}-db"
  db_name                = "appdb"
  master_username        = "postgres"
  master_password        = var.db_password # In real life, use Secrets Manager
  vpc_security_group_ids = [module.vpc.default_security_group_id]
  db_subnet_group_name   = module.vpc.database_subnet_group_name
  instance_count         = 1 # Dev Mode
  skip_final_snapshot    = true

  tags = local.tags
}

# ECS Service
module "ecs_service" {
  source = "../../modules/ecs-service"

  service_name       = "${local.name}-service"
  cluster_id         = aws_ecs_cluster.this.id
  cluster_name       = aws_ecs_cluster.this.name
  execution_role_arn = aws_iam_role.execution.arn
  
  container_image = "public.ecr.aws/nginx/nginx:latest" # Example
  
  subnet_ids         = module.vpc.private_subnets
  security_group_ids = [module.vpc.default_security_group_id]

  log_configuration = {
    logDriver = "awslogs"
    options = {
      "awslogs-group"         = module.observability.log_group_name
      "awslogs-region"        = local.region
      "awslogs-stream-prefix" = "ecs"
    }
  }

  environment_variables = [
    { name = "DB_HOST", value = module.aurora.cluster_endpoint },
    { name = "KAFKA_BROKERS", value = "mock-kafka:9092" } # Mocked dependency
  ]

  tags = local.tags
}

resource "aws_ecs_cluster" "this" {
  name = local.name
  tags = local.tags
}

# IAM Roles (Simplified for example)
resource "aws_iam_role" "execution" {
  name = "${local.name}-execution-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "execution" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
