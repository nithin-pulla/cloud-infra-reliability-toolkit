variable "name" {
  description = "Base name prefix for all security groups"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC in which to create the security groups"
  type        = string
}

variable "container_port" {
  description = "Port the ECS container listens on (used for ALB→ECS ingress/egress rules)"
  type        = number
  default     = 80
}

variable "tags" {
  description = "Tags to apply to all security groups"
  type        = map(string)
  default     = {}
}
