variable "app_name" {
  description = "Application name — used as a prefix for log group names, alarm names, and SNS topic names"
  type        = string
}

variable "retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 3653], var.retention_days)
    error_message = "retention_days must be a valid CloudWatch log retention value."
  }
}

variable "alarm_email" {
  description = "Email address to receive alarm notifications via SNS. Leave empty to skip subscription."
  type        = string
  default     = ""
}

# --- ECS Alarm Configuration ---

variable "ecs_cluster_name" {
  description = "ECS cluster name for alarm dimensions. Leave empty to skip ECS alarms."
  type        = string
  default     = ""
}

variable "ecs_service_name" {
  description = "ECS service name for alarm dimensions."
  type        = string
  default     = ""
}

variable "ecs_cpu_alarm_threshold" {
  description = "ECS CPU utilization percentage that triggers the critical alarm (should be above the autoscaling target)"
  type        = number
  default     = 85

  validation {
    condition     = var.ecs_cpu_alarm_threshold > 0 && var.ecs_cpu_alarm_threshold <= 100
    error_message = "ecs_cpu_alarm_threshold must be between 1 and 100."
  }
}

variable "ecs_memory_alarm_threshold" {
  description = "ECS memory utilization percentage that triggers the critical alarm"
  type        = number
  default     = 85

  validation {
    condition     = var.ecs_memory_alarm_threshold > 0 && var.ecs_memory_alarm_threshold <= 100
    error_message = "ecs_memory_alarm_threshold must be between 1 and 100."
  }
}

# --- Aurora Alarm Configuration ---

variable "aurora_cluster_id" {
  description = "Aurora cluster identifier for alarm dimensions. Leave empty to skip Aurora alarms."
  type        = string
  default     = ""
}

variable "aurora_has_replicas" {
  description = "Set to true when the Aurora cluster has read replicas to enable the replica lag alarm."
  type        = bool
  default     = false
}

variable "aurora_free_storage_threshold_bytes" {
  description = "Free storage threshold in bytes. Alarm fires when free storage falls below this value. Default is 10 GiB."
  type        = number
  default     = 10737418240 # 10 GiB
}

variable "aurora_max_connections_threshold" {
  description = "Database connection count threshold. Alarm fires when connections exceed this number. Set based on max_connections for your instance class."
  type        = number
  default     = 140 # ~80% of db.t3.medium max_connections (~170)
}

variable "aurora_replica_lag_threshold_ms" {
  description = "Aurora replica lag threshold in milliseconds. Alarm fires when lag exceeds this value."
  type        = number
  default     = 2000 # 2 seconds
}

# --- ALB Alarm Configuration ---

variable "alb_arn_suffix" {
  description = "ALB ARN suffix for alarm dimensions (the part after 'loadbalancer/'). Leave empty to skip ALB alarms."
  type        = string
  default     = ""
}

variable "target_group_arn_suffix" {
  description = "Target group ARN suffix for alarm dimensions (the part after 'targetgroup/')."
  type        = string
  default     = ""
}

variable "alb_5xx_threshold" {
  description = "Number of ALB 5xx responses per evaluation period that triggers the alarm"
  type        = number
  default     = 10
}

variable "tags" {
  description = "Tags applied to all observability resources"
  type        = map(string)
  default     = {}
}
