variable "name" {
  description = "Name for the ALB and related resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for the ALB"
  type        = list(string)
}

variable "alb_sg_id" {
  description = "Security group ID for the ALB"
  type        = string
}

variable "container_port" {
  description = "Port the ECS container listens on; used for target group"
  type        = number
  default     = 80
}

variable "health_check_path" {
  description = "Path used by the ALB health check"
  type        = string
  default     = "/health"
}

variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS. Leave empty to use HTTP-only (dev mode)."
  type        = string
  default     = ""
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection on the ALB"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
