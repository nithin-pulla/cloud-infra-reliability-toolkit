terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "/ecs/${var.app_name}-logs"
  retention_in_days = var.retention_days
  
  tags = var.tags
}

# Placeholder for DataDog / NewRelic forwarder
# resource "aws_cloudformation_stack" "datadog_forwarder" {
#   ...
# }
