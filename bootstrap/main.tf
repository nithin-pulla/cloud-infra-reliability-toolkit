# ---------------------------------------------------------------------------
# Remote State Bootstrap
#
# PURPOSE:
#   Creates the shared infrastructure required by all Terraform environments
#   to store remote state securely:
#     1. S3 bucket  — encrypted state storage with versioning
#     2. DynamoDB table — distributed state locking (prevents concurrent applies)
#
# USAGE (run once per AWS account):
#   cd bootstrap/
#   terraform init
#   terraform apply
#
#   After apply, copy the bucket name and table name from outputs and paste
#   them into each environment's backend.tf file, then run:
#     terraform init   (dev/   and prod/)
#
# STATE FOR THIS MODULE:
#   This module intentionally uses local state (no backend block).
#   Keep bootstrap/terraform.tfstate in a secure location (e.g. 1Password,
#   AWS Backup, or commit it to a private repo with encryption).
#
# ---------------------------------------------------------------------------

terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}

locals {
  bucket_name = "${var.bucket_name_prefix}-${data.aws_caller_identity.current.account_id}-${var.region}"
  tags = {
    Project   = "reliability-toolkit"
    ManagedBy = "terraform-bootstrap"
    Purpose   = "remote-state"
  }
}

# ---------------------------------------------------------------------------
# S3 Bucket — Terraform State Storage
#
# Security controls:
#   - Versioning: recover from accidental state corruption or deletion.
#   - AES-256 (SSE-S3) server-side encryption: state files contain
#     resource IDs and may contain sensitive plan output.
#   - Public access block: state must NEVER be publicly accessible.
#   - Force destroy disabled: prevents accidental deletion of state history.
#
# For stricter control, replace SSE-S3 with aws:kms and a customer-managed
# CMK to enforce key rotation and CloudTrail auditing of decryption events.
# ---------------------------------------------------------------------------
resource "aws_s3_bucket" "tfstate" {
  bucket        = local.bucket_name
  force_destroy = false

  tags = merge(local.tags, {
    Name = local.bucket_name
  })
}

resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  rule {
    id     = "expire-old-versions"
    status = "Enabled"

    noncurrent_version_expiration {
      # Keep the last 90 days of state history. Older noncurrent versions are
      # automatically deleted to manage storage cost.
      noncurrent_days = 90
    }
  }
}

# ---------------------------------------------------------------------------
# S3 Bucket Policy — Enforce Encrypted Transport
#
# Denies any request that does not use TLS (aws:SecureTransport = false).
# Prevents misconfigured clients from accidentally transmitting state over HTTP.
# ---------------------------------------------------------------------------
resource "aws_s3_bucket_policy" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.tfstate.arn,
          "${aws_s3_bucket.tfstate.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

# ---------------------------------------------------------------------------
# DynamoDB Table — State Locking
#
# Prevents two operators (or CI pipelines) from running `terraform apply`
# simultaneously and corrupting the state file.
#
# How locking works:
#   1. terraform init/plan/apply acquires a lock record in this table.
#   2. A second concurrent apply sees the lock and waits (or exits with error).
#   3. Once the first apply completes, it releases the lock.
#
# Attribute: LockID (String) — the primary key Terraform writes to.
# Billing: PAY_PER_REQUEST — no capacity planning needed; lock operations
# are few and short-lived.
#
# Point-in-time recovery provides a 35-day restore window for the lock table.
# ---------------------------------------------------------------------------
resource "aws_dynamodb_table" "tfstate_lock" {
  name         = var.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true # AES-256 encryption at rest
  }

  tags = merge(local.tags, {
    Name = var.dynamodb_table_name
  })
}
