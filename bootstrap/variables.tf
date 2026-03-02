variable "region" {
  description = "AWS region in which to create the state backend resources."
  type        = string
  default     = "us-east-1"
}

variable "bucket_name_prefix" {
  description = "Prefix for the S3 bucket name. The full name will be: <prefix>-<account_id>-<region>. Including the account ID and region ensures global uniqueness and prevents bucket squatting."
  type        = string
  default     = "tfstate-reliability-toolkit"
}

variable "dynamodb_table_name" {
  description = "Name of the DynamoDB table used for Terraform state locking."
  type        = string
  default     = "terraform-state-lock"
}
