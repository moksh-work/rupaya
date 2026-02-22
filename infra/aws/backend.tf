terraform {
  backend "s3" {
    bucket         = "rupaya-terraform-state-590184132516"
    key            = "prod/infrastructure/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "rupaya-terraform-state-lock"
    encrypt        = true
    # KMS key will be created during initial setup
    # kms_key_id     = "arn:aws:kms:us-east-1:590184132516:key/REPLACE_WITH_ACTUAL_KEY_ID"
  }
}
