variable "region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}

variable "db_password" {
  description = "Database master password. Use a tfvars file or TF_VAR_db_password env variable. Never commit plaintext credentials."
  type        = string
  sensitive   = true
  default     = "SuperSecretPass123!" # Default for dev example only — override in all real deployments
}

variable "alarm_email" {
  description = "Email address to receive CloudWatch alarm notifications. Leave empty to skip SNS email subscription."
  type        = string
  default     = ""
}

variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS termination. Leave empty in dev to use HTTP-only listener."
  type        = string
  default     = ""
}
