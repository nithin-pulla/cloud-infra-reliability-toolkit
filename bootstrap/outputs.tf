output "state_bucket_name" {
  description = "Name of the S3 bucket storing Terraform state"
  value       = aws_s3_bucket.tfstate.bucket
}

output "state_bucket_arn" {
  description = "ARN of the S3 bucket storing Terraform state"
  value       = aws_s3_bucket.tfstate.arn
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table used for state locking"
  value       = aws_dynamodb_table.tfstate_lock.name
}
