output "db_credentials_secret_arn" {
  description = "ARN of the database credentials secret. Grant secretsmanager:GetSecretValue on this ARN to the ECS task execution role."
  value       = aws_secretsmanager_secret.db_credentials.arn
}

output "db_credentials_secret_name" {
  description = "Name of the database credentials secret (path in Secrets Manager console)."
  value       = aws_secretsmanager_secret.db_credentials.name
}

output "app_secrets_arn" {
  description = "ARN of the application secrets. Grant secretsmanager:GetSecretValue on this ARN to the ECS task execution role."
  value       = aws_secretsmanager_secret.app_secrets.arn
}

output "app_secrets_name" {
  description = "Name of the application secrets (path in Secrets Manager console)."
  value       = aws_secretsmanager_secret.app_secrets.name
}

# ---------------------------------------------------------------------------
# ECS-ready secret references
#
# Wire directly to the `secrets` input of the ecs-service module:
#
#   module "ecs_service" {
#     ...
#     secrets = module.secrets.ecs_secret_refs
#   }
#
# ECS injects these as in-memory environment variables at task launch.
# The execution role must have secretsmanager:GetSecretValue on both ARNs.
#
# JSON-key extraction syntax: <secret_arn>:<json_key>::
#   The two trailing colons specify "latest version, default stage".
# ---------------------------------------------------------------------------
output "ecs_secret_refs" {
  description = "List of Secrets Manager references in ECS task definition `secrets` format. Includes DB_USERNAME, DB_PASSWORD from the credentials secret and JWT_SECRET from the app secrets."
  value = [
    {
      name      = "DB_USERNAME"
      valueFrom = "${aws_secretsmanager_secret.db_credentials.arn}:username::"
    },
    {
      name      = "DB_PASSWORD"
      valueFrom = "${aws_secretsmanager_secret.db_credentials.arn}:password::"
    },
    {
      name      = "JWT_SECRET"
      valueFrom = "${aws_secretsmanager_secret.app_secrets.arn}:jwt_secret::"
    }
  ]
}
