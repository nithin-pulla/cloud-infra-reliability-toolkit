terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

# ---------------------------------------------------------------------------
# Application Load Balancer
#
# Multi-AZ high availability:
#   - Subnets must span at least 2 AZs (3 in prod) in public subnets.
#   - ALB automatically distributes traffic across all healthy AZs.
#   - If an AZ fails, ALB stops routing to it; existing healthy AZs absorb load.
#
# Deletion protection prevents `terraform destroy` from removing a live ALB.
# Enable for production; disable for ephemeral dev/test environments.
#
# Access logs (optional): stored in S3 for audit trails and forensic analysis.
# Required for regulated workloads (PCI-DSS, HIPAA). Set access_log_bucket.
# ---------------------------------------------------------------------------
resource "aws_lb" "this" {
  name               = "${var.name_prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.security_group_id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = var.enable_deletion_protection

  # Drop malformed HTTP headers; prevents request smuggling attacks.
  drop_invalid_header_fields = true

  dynamic "access_logs" {
    for_each = var.access_log_bucket != "" ? [1] : []
    content {
      bucket  = var.access_log_bucket
      prefix  = var.access_log_prefix != "" ? var.access_log_prefix : var.name_prefix
      enabled = true
    }
  }

  tags = var.tags
}

# ---------------------------------------------------------------------------
# Target Group
#
# target_type = "ip" is REQUIRED for Fargate (network_mode = awsvpc).
# With awsvpc, each task gets its own ENI and IP — not the host IP.
#
# deregistration_delay = 30 s (default 300 s):
#   Reduces rolling deploy time. New task starts, old task drains connections
#   for only 30 s before being deregistered. Acceptable when the application
#   follows graceful shutdown conventions.
#
# Health check strategy:
#   - Path: configurable; use a dedicated /healthz endpoint that checks
#     internal dependencies (DB reachability, cache ping).
#   - unhealthy_threshold = 3: declares a task unhealthy after 3 consecutive
#     failures; prevents a single transient error from pulling the task.
#   - healthy_threshold = 2: re-registers a task after 2 consecutive successes;
#     quick recovery after a deployment rollout.
# ---------------------------------------------------------------------------
resource "aws_lb_target_group" "this" {
  name        = "${var.name_prefix}-tg"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  deregistration_delay = 30

  health_check {
    enabled             = true
    path                = var.health_check_path
    port                = "traffic-port"
    protocol            = "HTTP"
    healthy_threshold   = var.health_check_healthy_threshold
    unhealthy_threshold = var.health_check_unhealthy_threshold
    timeout             = var.health_check_timeout
    interval            = var.health_check_interval
    matcher             = var.health_check_matcher
  }

  tags = var.tags

  # create_before_destroy ensures a new target group is fully registered before
  # the old one is destroyed — required when replacing the TG (e.g. port change).
  lifecycle {
    create_before_destroy = true
  }
}

# ---------------------------------------------------------------------------
# HTTP Listener — Production: Redirect to HTTPS
#
# All port-80 traffic is redirected (301 Permanent) to HTTPS.
# This listener is created when certificate_arn is provided.
# 301 tells browsers and crawlers to update bookmarks permanently.
# ---------------------------------------------------------------------------
resource "aws_lb_listener" "http_redirect" {
  count = var.certificate_arn != "" ? 1 : 0

  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  tags = var.tags
}

# ---------------------------------------------------------------------------
# HTTPS Listener — Production: TLS Termination + Forward
#
# TLS terminates at the ALB; traffic to ECS tasks travels over the internal
# VPC network via HTTP (acceptable inside a private subnet + SG control).
#
# ssl_policy ELBSecurityPolicy-TLS13-1-2-2021-06:
#   - Allows TLS 1.2 and TLS 1.3
#   - Rejects TLS 1.0, TLS 1.1, SSLv3 (all deprecated, known vulnerabilities)
#   - Enforces forward secrecy via ECDHE cipher suites
#
# ACM certificate must cover the domain name used to reach the ALB.
# Request via: aws acm request-certificate --domain-name example.com
#              --validation-method DNS
# ---------------------------------------------------------------------------
resource "aws_lb_listener" "https" {
  count = var.certificate_arn != "" ? 1 : 0

  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }

  tags = var.tags
}

# ---------------------------------------------------------------------------
# HTTP Listener — Development: Direct Forward (no TLS)
#
# Created only when certificate_arn is empty (dev/local environments).
# Routes port-80 traffic directly to the ECS target group.
# DO NOT use in production — traffic is unencrypted.
# ---------------------------------------------------------------------------
resource "aws_lb_listener" "http_direct" {
  count = var.certificate_arn == "" ? 1 : 0

  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }

  tags = var.tags
}
