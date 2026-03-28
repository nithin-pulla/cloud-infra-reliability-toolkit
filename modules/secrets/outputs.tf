output "db_secret_arn" {
  description = "ARN of the database credentials secret"
  value       = aws_secretsmanager_secret.db.arn
}

output "app_secret_arn" {
  description = "ARN of the application secrets secret"
  value       = aws_secretsmanager_secret.app.arn
}

# Ready-to-use list for the ECS task definition `secrets` block.
# Each entry injects the whole JSON as a single env var; the application
# can parse it, or individual keys can be referenced via the JSON key path
# using the valueFrom ARN::jsonkey syntax in ECS.
output "ecs_secret_refs" {
  description = "List of ECS secret references suitable for the task definition secrets block"
  value = [
    {
      name      = "DB_CREDENTIALS"
      valueFrom = aws_secretsmanager_secret.db.arn
    },
    {
      name      = "APP_SECRETS"
      valueFrom = aws_secretsmanager_secret.app.arn
    },
  ]
}
