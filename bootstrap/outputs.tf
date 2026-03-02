output "tfstate_bucket_name" {
  description = "Name of the S3 bucket for Terraform state. Copy into backend.tf for each environment."
  value       = aws_s3_bucket.tfstate.id
}

output "tfstate_bucket_arn" {
  description = "ARN of the Terraform state S3 bucket."
  value       = aws_s3_bucket.tfstate.arn
}

output "tfstate_bucket_region" {
  description = "AWS region of the S3 bucket. Must match the `region` in backend.tf."
  value       = var.region
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB state locking table. Copy into backend.tf for each environment."
  value       = aws_dynamodb_table.tfstate_lock.name
}

output "dynamodb_table_arn" {
  description = "ARN of the DynamoDB state locking table."
  value       = aws_dynamodb_table.tfstate_lock.arn
}

output "next_steps" {
  description = "Instructions for activating the remote backend in each environment."
  value       = <<-EOT
    ============================================================
    Bootstrap complete. Next steps:
    ============================================================

    1. Copy the values above into examples/dev/backend.tf:

       terraform {
         backend "s3" {
           bucket         = "${aws_s3_bucket.tfstate.id}"
           key            = "reliability-toolkit/dev/terraform.tfstate"
           region         = "${var.region}"
           dynamodb_table = "${aws_dynamodb_table.tfstate_lock.name}"
           encrypt        = true
         }
       }

    2. Do the same for examples/prod/backend.tf, changing the key:
         key = "reliability-toolkit/prod/terraform.tfstate"

    3. In each environment directory, run:
         terraform init

       Terraform will ask: "Do you want to copy existing state to the new backend?"
       Answer: yes

    4. Verify the state was migrated:
         terraform state list

    ============================================================
  EOT
}
