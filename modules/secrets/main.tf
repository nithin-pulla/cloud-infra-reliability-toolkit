terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

resource "aws_secretsmanager_secret" "db" {
  name                    = "${var.app_name}/db/credentials"
  description             = "Database credentials for ${var.app_name}"
  recovery_window_in_days = var.recovery_window_in_days

  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
    host     = var.db_host
    port     = var.db_port
    dbname   = var.db_name
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}

resource "aws_secretsmanager_secret" "app" {
  name                    = "${var.app_name}/app/secrets"
  description             = "Application secrets for ${var.app_name}"
  recovery_window_in_days = var.recovery_window_in_days

  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "app" {
  secret_id     = aws_secretsmanager_secret.app.id
  secret_string = jsonencode(var.app_secrets)

  lifecycle {
    ignore_changes = [secret_string]
  }
}
