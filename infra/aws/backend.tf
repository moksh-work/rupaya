terraform {
  backend "s3" {
    bucket         = "rupaya-terraform-state-767397779454"
    key            = "prod/infrastructure/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "rupaya-terraform-state-lock"
    encrypt        = true
    kms_key_id     = "arn:aws:kms:us-east-1:767397779454:key/1724c7e3-359c-43f2-8fd7-07e75c22ce48"
  }
}
