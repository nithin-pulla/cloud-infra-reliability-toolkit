output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.this.name
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = module.ecs_service.service_name
}

output "aurora_writer_endpoint" {
  description = "Aurora PostgreSQL writer (primary) endpoint"
  value       = module.aurora.cluster_endpoint
}

output "aurora_reader_endpoint" {
  description = "Aurora PostgreSQL reader endpoint (load-balanced across replicas)"
  value       = module.aurora.reader_endpoint
}

output "log_group_name" {
  description = "CloudWatch log group name for ECS container logs"
  value       = module.observability.log_group_name
}

output "alarm_topic_arn" {
  description = "ARN of the SNS topic that receives all CloudWatch alarms"
  value       = module.observability.alarm_topic_arn
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "ecs_security_group_id" {
  description = "Security group ID attached to ECS tasks"
  value       = module.security_groups.ecs_security_group_id
}

output "aurora_security_group_id" {
  description = "Security group ID attached to Aurora instances"
  value       = module.security_groups.aurora_security_group_id
}
