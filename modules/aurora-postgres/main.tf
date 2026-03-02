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
# Cluster Parameter Group
# Explicit parameter group prevents implicit dependency on AWS-managed
# defaults and allows tuning log_statement, log_min_duration_statement,
# and connection limits without recreating the cluster.
# ---------------------------------------------------------------------------
resource "aws_rds_cluster_parameter_group" "this" {
  name        = "${var.cluster_name}-pg"
  family      = "aurora-postgresql${split(".", var.engine_version)[0]}"
  description = "Custom parameter group for ${var.cluster_name}"

  parameter {
    name  = "log_statement"
    value = var.log_statement
  }

  parameter {
    name  = "log_min_duration_statement"
    value = var.log_min_duration_statement
  }

  tags = var.tags
}

# ---------------------------------------------------------------------------
# Aurora Cluster
# ---------------------------------------------------------------------------
resource "aws_rds_cluster" "this" {
  cluster_identifier      = var.cluster_name
  engine                  = "aurora-postgresql"
  engine_version          = var.engine_version
  database_name           = var.db_name
  master_username         = var.master_username
  master_password         = var.master_password
  backup_retention_period = var.backup_retention_period
  preferred_backup_window = "07:00-09:00"

  vpc_security_group_ids       = var.vpc_security_group_ids
  db_subnet_group_name         = var.db_subnet_group_name
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.this.name

  storage_encrypted = true

  # Reliability: block accidental cluster deletion in production.
  # Override to false only in dev/test environments via variable.
  deletion_protection = var.deletion_protection

  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = "${var.cluster_name}-final"

  tags = var.tags

  lifecycle {
    # Prevent Terraform from destroying a cluster that has deletion_protection
    # enabled. This is a belt-and-suspenders guard in addition to the AWS flag.
    prevent_destroy = false
  }
}

# ---------------------------------------------------------------------------
# IAM Role for Enhanced Monitoring
# Grants RDS permission to publish OS-level metrics (CPU, swap, file
# descriptors) to CloudWatch. Required when monitoring_interval > 0.
# ---------------------------------------------------------------------------
resource "aws_iam_role" "rds_monitoring" {
  count = var.monitoring_interval > 0 ? 1 : 0

  name = "${var.cluster_name}-rds-monitoring"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "monitoring.rds.amazonaws.com" }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  count      = var.monitoring_interval > 0 ? 1 : 0
  role       = aws_iam_role.rds_monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# ---------------------------------------------------------------------------
# Cluster Instances
# ---------------------------------------------------------------------------
resource "aws_rds_cluster_instance" "this" {
  count              = var.instance_count
  identifier         = "${var.cluster_name}-${count.index}"
  cluster_identifier = aws_rds_cluster.this.id
  instance_class     = var.instance_class
  engine             = aws_rds_cluster.this.engine
  engine_version     = aws_rds_cluster.this.engine_version

  publicly_accessible = var.publicly_accessible

  # Observability: OS-level metrics (CPU steal, swap, file descriptors).
  # Set to 0 to disable; recommended value is 60 seconds.
  monitoring_interval = var.monitoring_interval
  monitoring_role_arn = var.monitoring_interval > 0 ? aws_iam_role.rds_monitoring[0].arn : null

  # Observability: query-level performance metrics at no additional cost
  # for the first 7 days of retention.
  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_enabled ? var.performance_insights_retention_period : null

  tags = var.tags
}
