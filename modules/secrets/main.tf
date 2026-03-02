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
# Database Credentials Secret
#
# Stores the Aurora master username and password as a JSON blob so that ECS
# can extract individual keys using the Secrets Manager JSON-key syntax:
#
#   arn:aws:secretsmanager:<region>:<account>:secret:<name>:json-key::
#
# This means the container never receives credentials as plaintext
# environment variables — they are fetched by the ECS agent at task launch
# and injected as in-memory environment variables inside the container.
#
# The execution role must have secretsmanager:GetSecretValue on this ARN.
# ---------------------------------------------------------------------------
resource "aws_secretsmanager_secret" "db_credentials" {
  name                    = "${var.app_name}/db/credentials"
  description             = "Aurora PostgreSQL master username and password"
  recovery_window_in_days = var.recovery_window_in_days

  tags = merge(var.tags, {
    SecretPurpose = "database-credentials"
  })
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
  })

  # After the initial seed, database credentials are rotated outside Terraform
  # (e.g. via Lambda rotation or the RDS console). Marking ignore_changes
  # prevents Terraform from reverting manually rotated secrets on the next apply.
  lifecycle {
    ignore_changes = [secret_string]
  }
}

# ---------------------------------------------------------------------------
# Application Secrets
#
# A separate secret namespace for application-level configuration: JWT signing
# keys, third-party API tokens, encryption keys, etc.
#
# The initial values are placeholder strings. After the first apply:
#   aws secretsmanager put-secret-value \
#     --secret-id <arn> \
#     --secret-string '{"jwt_secret":"real-value","app_key":"real-value"}'
#
# lifecycle.ignore_changes ensures subsequent Terraform runs do NOT overwrite
# values that were rotated or updated outside Terraform.
# ---------------------------------------------------------------------------
resource "aws_secretsmanager_secret" "app_secrets" {
  name                    = "${var.app_name}/app/secrets"
  description             = "Application-level secrets (JWT key, API tokens, etc.)"
  recovery_window_in_days = var.recovery_window_in_days

  tags = merge(var.tags, {
    SecretPurpose = "application-secrets"
  })
}

resource "aws_secretsmanager_secret_version" "app_secrets" {
  secret_id     = aws_secretsmanager_secret.app_secrets.id
  secret_string = jsonencode(var.app_secret_values)

  lifecycle {
    ignore_changes = [secret_string]
  }
}
