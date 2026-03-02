variable "app_name" {
  description = "Application name for log grouping"
  type        = string
}

variable "retention_days" {
  description = "Log retention in days"
  type        = number
  default     = 30
}

variable "tags" {
  description = "Tags"
  type        = map(string)
  default     = {}
}
