output "log_group_name" {
  description = "Name of the CloudWatch log group for ECS container logs"
  value       = aws_cloudwatch_log_group.app_logs.name
}

output "log_group_arn" {
  description = "ARN of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.app_logs.arn
}

output "alarm_topic_arn" {
  description = "ARN of the SNS topic that receives all CloudWatch alarm notifications"
  value       = aws_sns_topic.alarms.arn
}

output "alarm_topic_name" {
  description = "Name of the SNS alarm topic"
  value       = aws_sns_topic.alarms.name
}
