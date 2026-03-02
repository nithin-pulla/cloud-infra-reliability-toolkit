variable "cluster_name" {
  description = "Name of the Aurora cluster"
  type        = string
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
  description = "Days to retain backups"
  type        = number
  default     = 7
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
  description = "Number of instances (Writer + Readers). Set >1 for HA."
  type        = number
  default     = 1
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
  description = "Skip final snapshot on destroy"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}
