variable "service_name" {
  description = "Name of the ECS service and task family"
  type        = string
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
  description = "Fargate CPU units"
  type        = number
  default     = 256
}

variable "memory" {
  description = "Fargate Memory units"
  type        = number
  default     = 512
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
}

variable "autoscaling_min_capacity" {
  description = "Min capacity for autoscaling"
  type        = number
  default     = 1
}

variable "autoscaling_max_capacity" {
  description = "Max capacity for autoscaling"
  type        = number
  default     = 5
}

variable "autoscaling_cpu_threshold" {
  description = "CPU utilization % for autoscaling"
  type        = number
  default     = 70
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
