variable "name_prefix" {
  description = "Prefix applied to all security group names and tags"
  type        = string

  validation {
    condition     = length(var.name_prefix) > 0 && length(var.name_prefix) <= 40
    error_message = "name_prefix must be between 1 and 40 characters."
  }
}

variable "vpc_id" {
  description = "ID of the VPC in which to create all security groups"
  type        = string
}

variable "container_port" {
  description = "Port exposed by the ECS container (used for ALB → ECS ingress rule)"
  type        = number
  default     = 80

  validation {
    condition     = var.container_port > 0 && var.container_port <= 65535
    error_message = "container_port must be a valid port number (1–65535)."
  }
}

variable "tags" {
  description = "Tags applied to all security group resources"
  type        = map(string)
  default     = {}
}
