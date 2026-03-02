output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.alb.id
}

output "ecs_security_group_id" {
  description = "ID of the ECS task security group"
  value       = aws_security_group.ecs.id
}

output "aurora_security_group_id" {
  description = "ID of the Aurora PostgreSQL security group"
  value       = aws_security_group.aurora.id
}
