# ---------------------------------------------------------------------------
# Remote State Backend — PROD
#
# SETUP STEPS (one-time per AWS account):
#
#   1. Run the bootstrap workspace to create the shared S3 bucket and
#      DynamoDB table (if not already done for dev):
#        cd ../../bootstrap
#        terraform init
#        terraform apply
#
#   2. Replace the placeholder strings below with values from bootstrap output.
#
#   3. Run `terraform init` in this directory:
#        cd ../../examples/prod
#        terraform init
#
#   4. If migrating from local state:
#      Answer `yes` when Terraform asks to copy state to the new backend.
#
#   5. Verify: terraform state list
#
# ISOLATION:
#   Dev and prod share the same S3 bucket but use different `key` paths:
#     dev/  → reliability-toolkit/dev/terraform.tfstate
#     prod/ → reliability-toolkit/prod/terraform.tfstate
#   The DynamoDB lock table uses the full key path as the LockID, so dev
#   and prod can never acquire each other's lock.
#
# PRODUCTION HARDENING:
#   For defence in depth, restrict S3 bucket access via an IAM bucket policy
#   that allows only the CI/CD role and designated operator IAM users.
# ---------------------------------------------------------------------------

terraform {
  backend "s3" {
    bucket         = "REPLACE_WITH_BOOTSTRAP_OUTPUT_tfstate_bucket_name"
    key            = "reliability-toolkit/prod/terraform.tfstate"
    region         = "us-east-1" # must match the region used in bootstrap
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}
