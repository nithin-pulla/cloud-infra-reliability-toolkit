variable "region" {
  description = "AWS region to deploy bootstrap resources"
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "Globally unique S3 bucket name for Terraform state (override this per account)"
  type        = string
}

variable "dynamodb_table_name" {
  description = "DynamoDB table name for Terraform state locking"
  type        = string
  default     = "terraform-state-lock"
}

variable "tags" {
  description = "Tags to apply to bootstrap resources"
  type        = map(string)
  default = {
    ManagedBy = "terraform-bootstrap"
  }
}
