terraform {
  backend "s3" {
    # Override these values via -backend-config flags or a backend.hcl file:
    #   terraform init -backend-config="bucket=<your-bucket>" \
    #                  -backend-config="dynamodb_table=terraform-state-lock"
    bucket         = "REPLACE_WITH_YOUR_STATE_BUCKET"
    key            = "reliability-toolkit/prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
