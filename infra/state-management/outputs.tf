output "terraform_state_bucket" {
  description = "S3 bucket for Terraform state"
  value       = aws_s3_bucket.terraform_state.id
}

output "terraform_state_lock_table" {
  description = "DynamoDB table for state locking"
  value       = aws_dynamodb_table.terraform_state_lock.name
}

output "terraform_kms_key_id" {
  description = "KMS key ID for state encryption"
  value       = aws_kms_key.terraform_state.key_id
}

output "terraform_kms_key_arn" {
  description = "KMS key ARN for state encryption"
  value       = aws_kms_key.terraform_state.arn
}

output "cicd_role_arn" {
  description = "ARN of CI/CD role for assuming Terraform permissions"
  value       = aws_iam_role.terraform_cicd.arn
}

output "terraform_backend_policy_arn" {
  description = "ARN of backend access policy (attach to user/role)"
  value       = aws_iam_policy.terraform_backend.arn
}

output "backend_config" {
  description = "Backend configuration for terraform block"
  value = {
    bucket         = aws_s3_bucket.terraform_state.id
    key            = "prod/infrastructure/terraform.tfstate"
    region         = var.aws_region
    dynamodb_table = aws_dynamodb_table.terraform_state_lock.name
    kms_key_id     = aws_kms_key.terraform_state.id
    encrypt        = true
  }
}

output "s3_bucket_arn" {
  description = "ARN of S3 state bucket"
  value       = aws_s3_bucket.terraform_state.arn
}
