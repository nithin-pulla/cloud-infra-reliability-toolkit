output "lb_arn" {
  description = "ARN of the Application Load Balancer."
  value       = aws_lb.this.arn
}

output "lb_dns_name" {
  description = "DNS name of the ALB. Create a Route53 ALIAS record pointing to this value."
  value       = aws_lb.this.dns_name
}

output "lb_zone_id" {
  description = "Hosted zone ID of the ALB. Required for Route53 ALIAS records."
  value       = aws_lb.this.zone_id
}

output "lb_arn_suffix" {
  description = "ALB ARN suffix for use in CloudWatch metrics (e.g. app/<name>/<id>). Wire to the observability module's alb_arn_suffix variable."
  value       = aws_lb.this.arn_suffix
}

output "target_group_arn" {
  description = "ARN of the target group. Wire to the ecs-service module's target_group_arn variable to attach ECS tasks."
  value       = aws_lb_target_group.this.arn
}

output "target_group_arn_suffix" {
  description = "Target group ARN suffix for CloudWatch metrics (e.g. targetgroup/<name>/<id>). Wire to the observability module's target_group_arn_suffix variable."
  value       = aws_lb_target_group.this.arn_suffix
}

output "http_listener_arn" {
  description = "ARN of the HTTP listener (redirect to HTTPS in prod, direct forward in dev)."
  value       = var.certificate_arn != "" ? aws_lb_listener.http_redirect[0].arn : aws_lb_listener.http_direct[0].arn
}

output "https_listener_arn" {
  description = "ARN of the HTTPS listener. Null when certificate_arn is not provided."
  value       = var.certificate_arn != "" ? aws_lb_listener.https[0].arn : null
}
