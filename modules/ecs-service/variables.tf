variable "service_name" {
  description = "Name of the ECS service and task family"
  type        = string

  validation {
    condition     = length(var.service_name) > 0 && length(var.service_name) <= 255
    error_message = "service_name must be between 1 and 255 characters."
  }
}

variable "cluster_id" {
  description = "ID/ARN of the ECS cluster"
  type        = string
}

variable "cluster_name" {
    description = "Name of the ECS cluster (for autoscaling resource_id)"
    type = string
}

variable "cpu" {
  description = "Fargate CPU units (256, 512, 1024, 2048, 4096)"
  type        = number
  default     = 256

  validation {
    condition     = contains([256, 512, 1024, 2048, 4096], var.cpu)
    error_message = "cpu must be one of the valid Fargate CPU values: 256, 512, 1024, 2048, 4096."
  }
}

variable "memory" {
  description = "Fargate memory in MiB (must be compatible with chosen cpu value)"
  type        = number
  default     = 512

  validation {
    condition     = var.memory >= 512
    error_message = "memory must be at least 512 MiB."
  }
}

variable "container_name" {
  description = "Name of the container"
  type        = string
  default     = "app"
}

variable "container_image" {
  description = "Container image URI"
  type        = string
}

variable "container_port" {
  description = "Port exposed by the container"
  type        = number
  default     = 80
}

variable "execution_role_arn" {
  description = "ARN of the task execution role"
  type        = string
}

variable "task_role_arn" {
  description = "ARN of the task role"
  type        = string
  default     = ""
}

variable "subnet_ids" {
  description = "List of subnet IDs"
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of security group IDs"
  type        = list(string)
  default     = []
}

variable "assign_public_ip" {
  description = "Assign public IP to tasks"
  type        = bool
  default     = false
}

variable "target_group_arn" {
  description = "ARN of the target group for load balancing"
  type        = string
  default     = ""
}

variable "desired_count" {
  description = "Desired number of tasks"
  type        = number
  default     = 1

  validation {
    condition     = var.desired_count >= 1
    error_message = "desired_count must be at least 1."
  }
}

variable "deployment_minimum_healthy_percent" {
  description = "Lower bound on the number of running tasks that must remain healthy during a deployment, as a percentage of desired_count."
  type        = number
  default     = 100

  validation {
    condition     = var.deployment_minimum_healthy_percent >= 0 && var.deployment_minimum_healthy_percent <= 100
    error_message = "deployment_minimum_healthy_percent must be between 0 and 100."
  }
}

variable "deployment_maximum_percent" {
  description = "Upper bound on the number of running tasks allowed during a deployment, as a percentage of desired_count."
  type        = number
  default     = 200

  validation {
    condition     = var.deployment_maximum_percent >= 100
    error_message = "deployment_maximum_percent must be at least 100."
  }
}

variable "health_check_grace_period_seconds" {
  description = "Seconds to ignore failing health checks after a task starts. Set to the longest expected startup time of your container."
  type        = number
  default     = 60

  validation {
    condition     = var.health_check_grace_period_seconds >= 0
    error_message = "health_check_grace_period_seconds must be non-negative."
  }
}

variable "autoscaling_min_capacity" {
  description = "Minimum number of ECS tasks (autoscaling lower bound)"
  type        = number
  default     = 1

  validation {
    condition     = var.autoscaling_min_capacity >= 1
    error_message = "autoscaling_min_capacity must be at least 1."
  }
}

variable "autoscaling_max_capacity" {
  description = "Maximum number of ECS tasks (autoscaling upper bound)"
  type        = number
  default     = 5

  validation {
    condition     = var.autoscaling_max_capacity >= 1
    error_message = "autoscaling_max_capacity must be at least 1."
  }
}

variable "autoscaling_cpu_threshold" {
  description = "Target CPU utilization percentage for the CPU-based autoscaling policy"
  type        = number
  default     = 70

  validation {
    condition     = var.autoscaling_cpu_threshold > 0 && var.autoscaling_cpu_threshold <= 100
    error_message = "autoscaling_cpu_threshold must be between 1 and 100."
  }
}

variable "autoscaling_memory_threshold" {
  description = "Target memory utilization percentage for the memory-based autoscaling policy"
  type        = number
  default     = 75

  validation {
    condition     = var.autoscaling_memory_threshold > 0 && var.autoscaling_memory_threshold <= 100
    error_message = "autoscaling_memory_threshold must be between 1 and 100."
  }
}

variable "scale_in_cooldown" {
  description = "Seconds to wait after a scale-in event before another scale-in can occur"
  type        = number
  default     = 300

  validation {
    condition     = var.scale_in_cooldown >= 0
    error_message = "scale_in_cooldown must be non-negative."
  }
}

variable "scale_out_cooldown" {
  description = "Seconds to wait after a scale-out event before another scale-out can occur"
  type        = number
  default     = 60

  validation {
    condition     = var.scale_out_cooldown >= 0
    error_message = "scale_out_cooldown must be non-negative."
  }
}

variable "log_configuration" {
  description = "Log configuration for the container"
  type        = any
  default     = null
}

variable "environment_variables" {
  description = "Environment variables"
  type        = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "secrets" {
  description = "Secrets from Parameter Store or Secrets Manager"
  type = list(object({
    name = string
    valueFrom = string
  }))
  default = []
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
