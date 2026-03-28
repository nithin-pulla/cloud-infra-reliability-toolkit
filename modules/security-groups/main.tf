terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

# ALB Security Group
resource "aws_security_group" "alb" {
  name        = "${var.name}-alb-sg"
  description = "Allow inbound HTTP/HTTPS from internet; outbound to ECS"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description     = "To ECS tasks on container port"
    from_port       = var.container_port
    to_port         = var.container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id]
  }

  tags = merge(var.tags, { Name = "${var.name}-alb-sg" })
}

# ECS Security Group
resource "aws_security_group" "ecs" {
  name        = "${var.name}-ecs-sg"
  description = "Allow inbound from ALB; outbound to Aurora and internet (ECR/CloudWatch)"
  vpc_id      = var.vpc_id

  ingress {
    description     = "From ALB on container port"
    from_port       = var.container_port
    to_port         = var.container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description     = "To Aurora on PostgreSQL port"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.aurora.id]
  }

  egress {
    description = "HTTPS to internet (ECR image pulls, CloudWatch Logs, Secrets Manager)"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.name}-ecs-sg" })
}

# Aurora Security Group
resource "aws_security_group" "aurora" {
  name        = "${var.name}-aurora-sg"
  description = "Allow inbound PostgreSQL from ECS only"
  vpc_id      = var.vpc_id

  ingress {
    description     = "PostgreSQL from ECS tasks"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id]
  }

  tags = merge(var.tags, { Name = "${var.name}-aurora-sg" })
}
