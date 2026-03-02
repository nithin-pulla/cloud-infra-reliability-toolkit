# Backend configuration is in backend.tf.
# Run `terraform init` after filling in the bucket name and DynamoDB table
# from the bootstrap workspace output.

terraform {
  required_version = ">= 1.5"
}

provider "aws" {
  region = var.region
}

locals {
  name   = "reliability-toolkit-prod"
  region = var.region

  vpc_cidr = "10.1.0.0/16" # Separate CIDR from dev to allow VPC peering if needed
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)

  tags = {
    Environment = "prod"
    Project     = "reliability-toolkit"
    Terraform   = "true"
    ManagedBy   = "terraform"
  }
}

data "aws_availability_zones" "available" {}

# ---------------------------------------------------------------------------
# Network (VPC)
# Production: per-AZ NAT gateways for egress redundancy.
# A single NAT gateway is an AZ-level SPOF for all private subnet egress.
# ---------------------------------------------------------------------------
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = local.name
  cidr = local.vpc_cidr

  azs              = local.azs
  private_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k)]
  public_subnets   = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 4)]
  database_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 8)]

  enable_nat_gateway  = true
  single_nat_gateway  = false # Production: one NAT per AZ for redundancy
  one_nat_gateway_per_az = true

  create_database_subnet_group = true

  tags = local.tags
}

# ---------------------------------------------------------------------------
# Security Groups
# ---------------------------------------------------------------------------
module "security_groups" {
  source = "../../modules/security-groups"

  name_prefix    = local.name
  vpc_id         = module.vpc.vpc_id
  container_port = var.container_port
  tags           = local.tags
}

# ---------------------------------------------------------------------------
# Load Balancer
# Production: enable_deletion_protection = true prevents accidental removal.
# Set certificate_arn to an ACM certificate covering your domain name.
# The HTTP listener redirects all port-80 traffic to HTTPS (301).
#
# High-availability behaviour:
#   The ALB nodes are deployed across all 3 AZs listed in var.azs (above).
#   If an AZ fails, ALB stops routing to targets in that AZ automatically.
#   New task registrations triggered by ECS autoscaling land in healthy AZs.
# ---------------------------------------------------------------------------
module "alb" {
  source = "../../modules/alb"

  name_prefix        = local.name
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnets
  security_group_id  = module.security_groups.alb_security_group_id
  container_port     = var.container_port

  # Replace with a real ACM ARN:
  #   aws acm request-certificate --domain-name app.example.com --validation-method DNS
  certificate_arn = var.certificate_arn

  enable_deletion_protection = true
  access_log_bucket          = var.alb_access_log_bucket

  health_check_path = "/health"

  tags = local.tags
}

# ---------------------------------------------------------------------------
# Observability
# Production: alarm email is required; Aurora replica lag alarm is enabled.
# ---------------------------------------------------------------------------
module "observability" {
  source = "../../modules/observability"

  app_name    = local.name
  alarm_email = var.alarm_email

  ecs_cluster_name = aws_ecs_cluster.this.name
  ecs_service_name = "${local.name}-service"

  aurora_cluster_id   = module.aurora.cluster_id
  aurora_has_replicas = true # Production has read replicas

  # Wire ALB metrics so the 5xx alarm fires correctly.
  alb_arn_suffix          = module.alb.lb_arn_suffix
  target_group_arn_suffix = module.alb.target_group_arn_suffix

  tags = local.tags
}

# ---------------------------------------------------------------------------
# Secrets Manager
# Production: 30-day recovery window gives a month to recover from accidental
# deletion. After the initial seed, rotate credentials using either:
#   a) AWS-managed Lambda rotation for the Aurora secret, or
#   b) aws secretsmanager put-secret-value for app secrets.
# The ECS execution role fetches secrets at task launch — plaintext
# credentials are never written to task definitions or CloudWatch Logs.
# ---------------------------------------------------------------------------
module "secrets" {
  source = "../../modules/secrets"

  app_name    = local.name
  db_username = var.db_username
  db_password = var.db_password

  recovery_window_in_days = 30 # Production: 30-day soft-delete window

  tags = local.tags
}

# ---------------------------------------------------------------------------
# Database
# Production: Multi-AZ HA (instance_count = 2), deletion protection enabled,
# enhanced monitoring active, Performance Insights enabled.
# ---------------------------------------------------------------------------
module "aurora" {
  source = "../../modules/aurora-postgres"

  cluster_name           = "${local.name}-db"
  db_name                = var.db_name
  master_username        = var.db_username
  master_password        = var.db_password
  vpc_security_group_ids = [module.security_groups.aurora_security_group_id]
  db_subnet_group_name   = module.vpc.database_subnet_group_name

  # Production HA settings
  instance_count       = 2           # Writer + 1 read replica for automatic failover
  instance_class       = var.aurora_instance_class
  deletion_protection  = true        # Block accidental cluster deletion
  skip_final_snapshot  = false       # Always take a snapshot before destroy
  backup_retention_period = 14       # 2-week backup window for production

  # Observability
  monitoring_interval                  = 60   # Enhanced OS monitoring every 60s
  performance_insights_enabled         = true
  performance_insights_retention_period = 7   # 7-day free tier; upgrade to 731 for long-term

  tags = local.tags
}

# ---------------------------------------------------------------------------
# ECS Cluster
# ---------------------------------------------------------------------------
resource "aws_ecs_cluster" "this" {
  name = local.name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = local.tags
}

# ---------------------------------------------------------------------------
# IAM — Task Execution Role
# ---------------------------------------------------------------------------
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
  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "execution" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Least-privilege: restrict the execution role to fetching only the two secrets
# that belong to this environment. A compromised execution role cannot access
# secrets from other environments or other AWS accounts.
resource "aws_iam_role_policy" "execution_secrets" {
  name = "${local.name}-secrets-access"
  role = aws_iam_role.execution.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowSecretsManagerAccess"
        Effect = "Allow"
        Action = ["secretsmanager:GetSecretValue"]
        Resource = [
          module.secrets.db_credentials_secret_arn,
          module.secrets.app_secrets_arn,
        ]
      }
    ]
  })
}

# ---------------------------------------------------------------------------
# IAM — Task Role (Application Role)
# Scope this to the minimal set of permissions your application requires.
# Extend with additional aws_iam_role_policy_attachment resources as needed.
# ---------------------------------------------------------------------------
resource "aws_iam_role" "task" {
  name = "${local.name}-task-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
  tags = local.tags
}

# ---------------------------------------------------------------------------
# ECS Service
# Production: higher autoscaling ceiling, deployment config enforces zero
# downtime, health check grace period accounts for container warm-up.
# ---------------------------------------------------------------------------
module "ecs_service" {
  source = "../../modules/ecs-service"

  service_name       = "${local.name}-service"
  cluster_id         = aws_ecs_cluster.this.id
  cluster_name       = aws_ecs_cluster.this.name
  execution_role_arn = aws_iam_role.execution.arn
  task_role_arn      = aws_iam_role.task.arn

  container_image = var.container_image
  container_port  = var.container_port
  cpu             = var.task_cpu
  memory          = var.task_memory

  subnet_ids         = module.vpc.private_subnets
  security_group_ids = [module.security_groups.ecs_security_group_id]

  # Production deployment safety: always keep 100% of tasks healthy during
  # rolling updates; allow up to double capacity during the transition.
  deployment_minimum_healthy_percent  = 100
  deployment_maximum_percent          = 200
  health_check_grace_period_seconds   = 120

  log_configuration = {
    logDriver = "awslogs"
    options = {
      "awslogs-group"         = module.observability.log_group_name
      "awslogs-region"        = local.region
      "awslogs-stream-prefix" = "ecs"
    }
  }

  # Wire the ALB target group so ECS registers task IPs as targets.
  target_group_arn = module.alb.target_group_arn

  # DB credentials and app secrets are injected at launch time by the ECS
  # agent via Secrets Manager — never stored in plaintext in the task def.
  secrets = module.secrets.ecs_secret_refs

  environment_variables = [
    # DB_HOST and DB_READER_HOST are not sensitive — they are DNS names.
    # DB_USERNAME and DB_PASSWORD arrive via secrets (see above).
    { name = "DB_HOST",        value = module.aurora.cluster_endpoint },
    { name = "DB_READER_HOST", value = module.aurora.reader_endpoint },
    { name = "KAFKA_BROKERS",  value = var.kafka_brokers }
  ]

  # Production: larger autoscaling range, tighter cooldowns
  autoscaling_min_capacity      = var.autoscaling_min
  autoscaling_max_capacity      = var.autoscaling_max
  autoscaling_cpu_threshold     = 70
  autoscaling_memory_threshold  = 75
  scale_in_cooldown             = 300
  scale_out_cooldown            = 60

  tags = local.tags
}
