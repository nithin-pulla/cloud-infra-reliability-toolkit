variable "app_name" {
  description = "Application name, used as prefix for secret paths (e.g. myapp → myapp/db/credentials)"
  type        = string
}

variable "db_username" {
  description = "Database master username stored in the DB credentials secret"
  type        = string
}

variable "db_password" {
  description = "Database master password stored in the DB credentials secret"
  type        = string
  sensitive   = true
}

variable "db_host" {
  description = "Database host (cluster endpoint) stored in the DB credentials secret"
  type        = string
}

variable "db_port" {
  description = "Database port stored in the DB credentials secret"
  type        = number
  default     = 5432
}

variable "db_name" {
  description = "Database name stored in the DB credentials secret"
  type        = string
}

variable "app_secrets" {
  description = "Map of arbitrary key/value pairs to store as the application secrets JSON"
  type        = map(string)
  default     = {}
  sensitive   = true
}

variable "recovery_window_in_days" {
  description = "Number of days Secrets Manager waits before deleting a secret (0 = immediate)"
  type        = number
  default     = 7
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
