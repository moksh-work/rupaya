# Remote Terraform State (S3 + DynamoDB)

This repo now uses a remote backend for Terraform state in CI/CD.

## Required AWS Resources

1. **S3 bucket** for state
2. **DynamoDB table** for state locking

### Recommended settings
- S3 bucket: versioning enabled, default encryption enabled
- DynamoDB table: partition key `LockID` (string)

## Required GitHub Secrets

Add these repository secrets:

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_REGION` (optional, defaults to us-east-1)
- `TFSTATE_BUCKET`
- `TFSTATE_DYNAMODB_TABLE`
- `TFSTATE_KEY`

Example `TFSTATE_KEY` value:
```
infra/aws/terraform.tfstate
```

## Local Initialization

Run Terraform init with backend config values:

```
terraform init \
  -backend-config="bucket=<TFSTATE_BUCKET>" \
  -backend-config="key=<TFSTATE_KEY>" \
  -backend-config="region=<AWS_REGION>" \
  -backend-config="dynamodb_table=<TFSTATE_DYNAMODB_TABLE>" \
  -backend-config="encrypt=true"
```

## CI/CD Initialization

The workflow uses the same backend config values from GitHub Secrets.

See: [.github/workflows/terraform-staged-deploy.yml](.github/workflows/terraform-staged-deploy.yml)
