variable "cluster_name" {
  description = "Name of the Aurora cluster"
  type        = string

  validation {
    condition     = length(var.cluster_name) > 0 && length(var.cluster_name) <= 63
    error_message = "cluster_name must be between 1 and 63 characters."
  }
}

variable "engine_version" {
  description = "Aurora PostgreSQL engine version"
  type        = string
  default     = "15.4"
}

variable "db_name" {
  description = "Name of the initial database"
  type        = string
}

variable "master_username" {
  description = "Master username"
  type        = string
}

variable "master_password" {
  description = "Master password"
  type        = string
  sensitive   = true
}

variable "backup_retention_period" {
  description = "Days to retain automated backups (1–35)"
  type        = number
  default     = 7

  validation {
    condition     = var.backup_retention_period >= 1 && var.backup_retention_period <= 35
    error_message = "backup_retention_period must be between 1 and 35 days."
  }
}

variable "vpc_security_group_ids" {
  description = "List of VPC security group IDs"
  type        = list(string)
}

variable "db_subnet_group_name" {
  description = "Name of DB subnet group"
  type        = string
}

variable "instance_count" {
  description = "Number of cluster instances. Set 1 for dev (writer only), 2+ for production HA with automatic failover."
  type        = number
  default     = 1

  validation {
    condition     = var.instance_count >= 1
    error_message = "instance_count must be at least 1."
  }
}

variable "instance_class" {
  description = "Instance class for cluster instances"
  type        = string
  default     = "db.t3.medium"
}

variable "publicly_accessible" {
  description = "Expose DB publicly (NOT RECOMMENDED for prod)"
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot on destroy. Set to false in all production environments."
  type        = bool
  default     = false
}

variable "deletion_protection" {
  description = "Enable deletion protection on the Aurora cluster. Blocks destroy operations. Disable only in dev/test."
  type        = bool
  default     = true
}

variable "monitoring_interval" {
  description = "Interval (seconds) for Enhanced Monitoring OS metrics. 0 disables enhanced monitoring. Valid values: 0, 1, 5, 10, 15, 30, 60."
  type        = number
  default     = 60

  validation {
    condition     = contains([0, 1, 5, 10, 15, 30, 60], var.monitoring_interval)
    error_message = "monitoring_interval must be one of: 0, 1, 5, 10, 15, 30, 60."
  }
}

variable "performance_insights_enabled" {
  description = "Enable Aurora Performance Insights for query-level observability."
  type        = bool
  default     = true
}

variable "performance_insights_retention_period" {
  description = "Days to retain Performance Insights data. Free tier is 7 days; paid retention is 731 days."
  type        = number
  default     = 7

  validation {
    condition     = var.performance_insights_retention_period == 7 || var.performance_insights_retention_period == 731
    error_message = "performance_insights_retention_period must be 7 (free) or 731 (paid)."
  }
}

variable "log_statement" {
  description = "Controls which SQL statements are logged. Valid values: none, ddl, mod, all."
  type        = string
  default     = "ddl"

  validation {
    condition     = contains(["none", "ddl", "mod", "all"], var.log_statement)
    error_message = "log_statement must be one of: none, ddl, mod, all."
  }
}

variable "log_min_duration_statement" {
  description = "Log queries that take longer than this value in milliseconds. -1 disables. Useful for identifying slow queries."
  type        = number
  default     = 1000
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}
