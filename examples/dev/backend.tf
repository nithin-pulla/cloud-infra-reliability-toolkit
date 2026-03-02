# ---------------------------------------------------------------------------
# Remote State Backend — DEV
#
# SETUP STEPS (one-time per AWS account):
#
#   1. Create the S3 bucket and DynamoDB table by running the bootstrap:
#        cd ../../bootstrap
#        terraform init
#        terraform apply
#
#   2. Copy the output values from bootstrap into this file, replacing the
#      placeholder strings below.
#
#   3. Run `terraform init` in this directory:
#        cd ../../examples/dev
#        terraform init
#
#      Terraform will prompt:
#        "Do you want to copy existing state to the new backend? [yes/no]"
#      Answer `yes` to migrate existing local state to S3.
#
#   4. Verify the migration:
#        terraform state list
#
#   5. Delete the local state file (now redundant):
#        rm terraform.tfstate terraform.tfstate.backup
#
# LOCKING:
#   DynamoDB prevents two concurrent `terraform apply` runs from corrupting
#   the state. If an apply is interrupted mid-run, remove the stale lock:
#     terraform force-unlock <lock-id>
#
# SECURITY:
#   The S3 bucket enforces server-side encryption (AES-256) and blocks all
#   public access. State files may contain resource IDs and secret ARNs.
# ---------------------------------------------------------------------------

terraform {
  backend "s3" {
    bucket         = "REPLACE_WITH_BOOTSTRAP_OUTPUT_tfstate_bucket_name"
    key            = "reliability-toolkit/dev/terraform.tfstate"
    region         = "us-east-1" # must match the region used in bootstrap
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}
