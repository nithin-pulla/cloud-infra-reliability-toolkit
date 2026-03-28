output "lb_dns_name" {
  description = "DNS name of the load balancer"
  value       = aws_lb.this.dns_name
}

output "lb_arn" {
  description = "ARN of the load balancer"
  value       = aws_lb.this.arn
}

output "lb_arn_suffix" {
  description = "ARN suffix of the load balancer (used in CloudWatch metrics)"
  value       = aws_lb.this.arn_suffix
}

output "target_group_arn" {
  description = "ARN of the target group"
  value       = aws_lb_target_group.this.arn
}

output "target_group_arn_suffix" {
  description = "ARN suffix of the target group (used in CloudWatch metrics)"
  value       = aws_lb_target_group.this.arn_suffix
}
