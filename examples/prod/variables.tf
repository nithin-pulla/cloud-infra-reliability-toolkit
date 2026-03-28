variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "db_password" {
  description = "Aurora master password — supply via TF_VAR_db_password or a secrets backend; never hardcode"
  type        = string
  sensitive   = true
}

variable "certificate_arn" {
  description = "ACM certificate ARN for the HTTPS listener (required in prod)"
  type        = string
}
