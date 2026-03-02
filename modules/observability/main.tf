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
# CloudWatch Log Group
# ---------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "/ecs/${var.app_name}-logs"
  retention_in_days = var.retention_days
  tags              = var.tags
}

# ---------------------------------------------------------------------------
# SNS Alarm Topic
# All CloudWatch alarms publish to this topic. Subscribe an email address,
# PagerDuty endpoint, or Slack webhook via SNS subscription separately.
# ---------------------------------------------------------------------------
resource "aws_sns_topic" "alarms" {
  name = "${var.app_name}-alarms"
  tags = var.tags
}

resource "aws_sns_topic_subscription" "email" {
  count     = var.alarm_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

# ---------------------------------------------------------------------------
# ECS Alarms
# ---------------------------------------------------------------------------

# Alarm: ECS CPU is critically high (above autoscaling threshold — service
# is at or near maximum capacity and cannot scale further).
resource "aws_cloudwatch_metric_alarm" "ecs_cpu_high" {
  count = var.ecs_cluster_name != "" ? 1 : 0

  alarm_name          = "${var.app_name}-ecs-cpu-high"
  alarm_description   = "ECS CPU utilization is critically high. Service may be at max capacity."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = var.ecs_cpu_alarm_threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = var.ecs_service_name
  }

  alarm_actions = [aws_sns_topic.alarms.arn]
  ok_actions    = [aws_sns_topic.alarms.arn]
  tags          = var.tags
}

# Alarm: ECS memory utilization is critically high.
resource "aws_cloudwatch_metric_alarm" "ecs_memory_high" {
  count = var.ecs_cluster_name != "" ? 1 : 0

  alarm_name          = "${var.app_name}-ecs-memory-high"
  alarm_description   = "ECS memory utilization is critically high."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = var.ecs_memory_alarm_threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = var.ecs_service_name
  }

  alarm_actions = [aws_sns_topic.alarms.arn]
  ok_actions    = [aws_sns_topic.alarms.arn]
  tags          = var.tags
}

# ---------------------------------------------------------------------------
# Aurora / RDS Alarms
# ---------------------------------------------------------------------------

# Alarm: Aurora free storage is critically low.
resource "aws_cloudwatch_metric_alarm" "aurora_free_storage_low" {
  count = var.aurora_cluster_id != "" ? 1 : 0

  alarm_name          = "${var.app_name}-aurora-free-storage-low"
  alarm_description   = "Aurora free storage is critically low. Risk of cluster unavailability."
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "FreeLocalStorage"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = var.aurora_free_storage_threshold_bytes
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBClusterIdentifier = var.aurora_cluster_id
  }

  alarm_actions = [aws_sns_topic.alarms.arn]
  ok_actions    = [aws_sns_topic.alarms.arn]
  tags          = var.tags
}

# Alarm: Aurora database connection count is approaching the instance limit.
resource "aws_cloudwatch_metric_alarm" "aurora_connections_high" {
  count = var.aurora_cluster_id != "" ? 1 : 0

  alarm_name          = "${var.app_name}-aurora-connections-high"
  alarm_description   = "Aurora connection count is high. Risk of connection pool exhaustion."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = 60
  statistic           = "Average"
  threshold           = var.aurora_max_connections_threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBClusterIdentifier = var.aurora_cluster_id
  }

  alarm_actions = [aws_sns_topic.alarms.arn]
  ok_actions    = [aws_sns_topic.alarms.arn]
  tags          = var.tags
}

# Alarm: Aurora replica lag is elevated, indicating replication is falling behind.
resource "aws_cloudwatch_metric_alarm" "aurora_replica_lag" {
  count = var.aurora_cluster_id != "" && var.aurora_has_replicas ? 1 : 0

  alarm_name          = "${var.app_name}-aurora-replica-lag"
  alarm_description   = "Aurora replica lag is high. Replica reads may return stale data."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "AuroraReplicaLag"
  namespace           = "AWS/RDS"
  period              = 60
  statistic           = "Average"
  threshold           = var.aurora_replica_lag_threshold_ms
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBClusterIdentifier = var.aurora_cluster_id
  }

  alarm_actions = [aws_sns_topic.alarms.arn]
  ok_actions    = [aws_sns_topic.alarms.arn]
  tags          = var.tags
}

# ---------------------------------------------------------------------------
# ALB Alarms
# ---------------------------------------------------------------------------

# Alarm: ALB 5xx error rate is elevated, indicating application or target errors.
resource "aws_cloudwatch_metric_alarm" "alb_5xx_errors" {
  count = var.alb_arn_suffix != "" && var.target_group_arn_suffix != "" ? 1 : 0

  alarm_name          = "${var.app_name}-alb-5xx-errors"
  alarm_description   = "ALB 5xx error count is elevated. Application errors may be occurring."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = var.alb_5xx_threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
    TargetGroup  = var.target_group_arn_suffix
  }

  alarm_actions = [aws_sns_topic.alarms.arn]
  ok_actions    = [aws_sns_topic.alarms.arn]
  tags          = var.tags
}

# ---------------------------------------------------------------------------
# Placeholder for DataDog / New Relic APM forwarder
# Uncomment and populate when APM integration is required.
# ---------------------------------------------------------------------------
# resource "aws_cloudformation_stack" "datadog_forwarder" {
#   name         = "${var.app_name}-datadog-forwarder"
#   template_url = "https://datadog-cloudformation-template.s3.amazonaws.com/..."
#   capabilities = ["CAPABILITY_IAM", "CAPABILITY_NAMED_IAM"]
#   parameters   = {
#     DdApiKey = var.datadog_api_key
#     FunctionName = "${var.app_name}-datadog-forwarder"
#   }
# }
