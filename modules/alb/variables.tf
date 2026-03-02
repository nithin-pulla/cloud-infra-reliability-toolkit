variable "name_prefix" {
  description = "Prefix used for all ALB and target group resource names."
  type        = string

  validation {
    condition     = length(var.name_prefix) > 0 && length(var.name_prefix) <= 32
    error_message = "name_prefix must be between 1 and 32 characters (ALB name limit is 32)."
  }
}

variable "vpc_id" {
  description = "ID of the VPC in which to create the target group."
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for the ALB. Must span at least 2 AZs for high availability."
  type        = list(string)

  validation {
    condition     = length(var.public_subnet_ids) >= 2
    error_message = "At least 2 public subnets in different AZs are required for ALB high availability."
  }
}

variable "security_group_id" {
  description = "ID of the security group to attach to the ALB. Should allow inbound 80 and 443 from the internet."
  type        = string
}

variable "container_port" {
  description = "Port on which the ECS containers listen. Used as the target group port."
  type        = number
  default     = 80

  validation {
    condition     = var.container_port > 0 && var.container_port <= 65535
    error_message = "container_port must be a valid TCP port (1–65535)."
  }
}

variable "certificate_arn" {
  description = <<-EOT
    ACM certificate ARN for HTTPS termination. When provided:
      - Port 443 HTTPS listener is created with TLS 1.2+
      - Port 80 listener redirects to HTTPS (301)
    When empty:
      - Only a port-80 HTTP listener is created (dev/test only)
    
    Obtain a cert: aws acm request-certificate --domain-name example.com \
                     --validation-method DNS
  EOT
  type    = string
  default = ""
}

variable "enable_deletion_protection" {
  description = "Prevents the ALB from being destroyed by terraform destroy. Set true in production."
  type        = bool
  default     = false
}

variable "access_log_bucket" {
  description = "S3 bucket name for ALB access logs. Leave empty to disable. Required for PCI-DSS / HIPAA."
  type        = string
  default     = ""
}

variable "access_log_prefix" {
  description = "S3 key prefix for ALB access logs. Defaults to name_prefix if not set."
  type        = string
  default     = ""
}

variable "health_check_path" {
  description = "HTTP path used by the ALB to check target health. Recommended: a /healthz endpoint that checks DB connectivity."
  type        = string
  default     = "/health"
}

variable "health_check_interval" {
  description = "Seconds between health check requests (10–300)."
  type        = number
  default     = 30

  validation {
    condition     = var.health_check_interval >= 10 && var.health_check_interval <= 300
    error_message = "health_check_interval must be between 10 and 300 seconds."
  }
}

variable "health_check_timeout" {
  description = "Seconds the ALB waits for a health check response (2–120, must be less than interval)."
  type        = number
  default     = 5
}

variable "health_check_healthy_threshold" {
  description = "Consecutive successful health checks required to mark a target healthy (2–10)."
  type        = number
  default     = 2
}

variable "health_check_unhealthy_threshold" {
  description = "Consecutive failed health checks required to mark a target unhealthy (2–10)."
  type        = number
  default     = 3
}

variable "health_check_matcher" {
  description = "HTTP response codes considered healthy (e.g. '200' or '200-299')."
  type        = string
  default     = "200"
}

variable "tags" {
  description = "Tags to apply to all ALB resources."
  type        = map(string)
  default     = {}
}
