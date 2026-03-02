variable "app_name" {
  description = "Application name used as the Secrets Manager path prefix (e.g. 'reliability-toolkit-prod'). Secrets will be named <app_name>/db/credentials and <app_name>/app/secrets."
  type        = string

  validation {
    condition     = length(var.app_name) > 0 && length(var.app_name) <= 100
    error_message = "app_name must be between 1 and 100 characters."
  }
}

variable "db_username" {
  description = "Database master username to store in the credentials secret."
  type        = string
  default     = "postgres"
}

variable "db_password" {
  description = "Database master password to store in the credentials secret. Provide via TF_VAR_db_password environment variable. Never hardcode."
  type        = string
  sensitive   = true
}

variable "app_secret_values" {
  description = <<-EOT
    Initial key-value map of application secrets written to Secrets Manager on
    the first apply. After the first apply, rotate values outside Terraform:

      aws secretsmanager put-secret-value \
        --secret-id <arn> \
        --secret-string '{"jwt_secret":"<new>","app_key":"<new>"}'

    The lifecycle ignore_changes block prevents subsequent applies from
    overwriting manually rotated values.
  EOT
  type        = map(string)
  sensitive   = true
  default = {
    jwt_secret = "REPLACE_BEFORE_PRODUCTION"
    app_key    = "REPLACE_BEFORE_PRODUCTION"
  }
}

variable "recovery_window_in_days" {
  description = <<-EOT
    Days Secrets Manager waits before permanently deleting a secret after
    aws_secretsmanager_secret is destroyed. Valid values: 0 (force delete,
    removes immediately) or 7–30 (scheduled deletion window). Use 0 in dev
    to enable rapid teardown; use 30 in production for accidental-delete
    recovery.
  EOT
  type    = number
  default = 7

  validation {
    condition     = var.recovery_window_in_days == 0 || (var.recovery_window_in_days >= 7 && var.recovery_window_in_days <= 30)
    error_message = "recovery_window_in_days must be 0 (force delete) or between 7 and 30."
  }
}

variable "tags" {
  description = "Tags to apply to all Secrets Manager resources."
  type        = map(string)
  default     = {}
}
