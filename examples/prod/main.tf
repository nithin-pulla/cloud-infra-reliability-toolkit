terraform {
  required_version = ">= 1.5"
}

provider "aws" {
  region = var.region
}

locals {
  name   = "reliability-toolkit-prod"
  region = var.region

  vpc_cidr = "10.1.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)

  tags = {
    Environment = "prod"
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

  azs              = local.azs
  private_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k)]
  public_subnets   = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 4)]
  database_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 8)]

  enable_nat_gateway = true
  single_nat_gateway = false # One NAT GW per AZ for HA

  create_database_subnet_group = true

  tags = local.tags
}

# Security Groups
module "security_groups" {
  source = "../../modules/security-groups"

  name           = local.name
  vpc_id         = module.vpc.vpc_id
  container_port = 80
  tags           = local.tags
}

# Observability
module "observability" {
  source = "../../modules/observability"

  app_name       = local.name
  retention_days = 90
  tags           = local.tags
}

# Database
module "aurora" {
  source = "../../modules/aurora-postgres"

  cluster_name           = "${local.name}-db"
  db_name                = "appdb"
  master_username        = "postgres"
  master_password        = var.db_password
  vpc_security_group_ids = [module.security_groups.aurora_sg_id]
  db_subnet_group_name   = module.vpc.database_subnet_group_name
  instance_count         = 2 # Writer + Reader for HA
  skip_final_snapshot    = false

  tags = local.tags
}

# Secrets Manager
module "secrets" {
  source = "../../modules/secrets"

  app_name    = local.name
  db_username = "postgres"
  db_password = var.db_password
  db_host     = module.aurora.cluster_endpoint
  db_name     = "appdb"
  app_secrets = {}

  recovery_window_in_days = 30

  tags = local.tags
}

# Application Load Balancer
module "alb" {
  source = "../../modules/alb"

  name              = local.name
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnets
  alb_sg_id         = module.security_groups.alb_sg_id
  container_port    = 80
  health_check_path = "/health"
  certificate_arn   = var.certificate_arn # HTTPS enforced in prod

  enable_deletion_protection = true

  tags = local.tags
}

# ECS Cluster
resource "aws_ecs_cluster" "this" {
  name = local.name
  tags = local.tags
}

# IAM Roles
resource "aws_iam_role" "execution" {
  name = "${local.name}-execution-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "execution" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Allow the execution role to read secrets from Secrets Manager
resource "aws_iam_role_policy" "execution_secrets" {
  name = "${local.name}-execution-secrets"
  role = aws_iam_role.execution.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret",
      ]
      Resource = [
        module.secrets.db_secret_arn,
        module.secrets.app_secret_arn,
      ]
    }]
  })
}

# ECS Service
module "ecs_service" {
  source = "../../modules/ecs-service"

  service_name       = "${local.name}-service"
  cluster_id         = aws_ecs_cluster.this.id
  cluster_name       = aws_ecs_cluster.this.name
  execution_role_arn = aws_iam_role.execution.arn

  container_image = "public.ecr.aws/nginx/nginx:latest"

  desired_count            = 2
  autoscaling_min_capacity = 2
  autoscaling_max_capacity = 10

  subnet_ids         = module.vpc.private_subnets
  security_group_ids = [module.security_groups.ecs_sg_id]
  target_group_arn   = module.alb.target_group_arn

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
    { name = "DB_READER_HOST", value = module.aurora.reader_endpoint },
  ]

  secrets = module.secrets.ecs_secret_refs

  tags = local.tags
}
