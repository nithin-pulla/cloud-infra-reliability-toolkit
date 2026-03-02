variable "region" {
  description = "AWS Region for the production environment"
  type        = string
  default     = "us-east-1"
}

variable "alarm_email" {
  description = "Email address for CloudWatch alarm notifications. Required in production."
  type        = string

  validation {
    condition     = length(var.alarm_email) > 0
    error_message = "alarm_email is required for the production environment."
  }
}

variable "db_name" {
  description = "Name of the initial Aurora database"
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Aurora master username"
  type        = string
  default     = "postgres"
}

variable "db_password" {
  description = "Aurora master password. Provide via TF_VAR_db_password environment variable or Secrets Manager. Never hardcode."
  type        = string
  sensitive   = true
}

variable "aurora_instance_class" {
  description = "RDS instance class for Aurora cluster instances"
  type        = string
  default     = "db.r6g.large" # Production: r-class instance for better memory/CPU ratio
}

variable "container_image" {
  description = "Fully-qualified container image URI (e.g., 123456789.dkr.ecr.us-east-1.amazonaws.com/app:v1.2.3)"
  type        = string
}

variable "container_port" {
  description = "Port exposed by the application container"
  type        = number
  default     = 8080
}

variable "task_cpu" {
  description = "Fargate task CPU units"
  type        = number
  default     = 1024
}

variable "task_memory" {
  description = "Fargate task memory in MiB"
  type        = number
  default     = 2048
}

variable "autoscaling_min" {
  description = "Minimum number of running ECS tasks"
  type        = number
  default     = 2 # Production: always run minimum 2 tasks for HA
}

variable "autoscaling_max" {
  description = "Maximum number of running ECS tasks"
  type        = number
  default     = 10
}

variable "kafka_brokers" {
  description = "Comma-separated list of Kafka broker addresses"
  type        = string
  default     = "mock-kafka:9092" # Replace with real brokers in production
}

variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS termination on the ALB. Must cover the domain pointed at the ALB DNS name. Obtain with: aws acm request-certificate --domain-name app.example.com --validation-method DNS"
  type        = string
  default     = "" # Set to a real ARN; leaving empty creates an HTTP-only listener
}

variable "alb_access_log_bucket" {
  description = "S3 bucket name for ALB access logs. Required for PCI-DSS and HIPAA workloads. Leave empty to disable."
  type        = string
  default     = ""
}
