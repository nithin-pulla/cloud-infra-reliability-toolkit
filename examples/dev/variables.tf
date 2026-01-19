variable "region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
  default     = "SuperSecretPass123!" # Default for dev example only!
}
