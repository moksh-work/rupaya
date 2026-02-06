# Rupaya Terraform Environments

This directory contains environment-specific variable files for Terraform deployments.

## Environments
- `development.tfvars`: Developer sandbox, preview, or local integration.
- `sandbox.tfvars`: Isolated preview or QA environment.
- `staging.tfvars`: Pre-production, mirrors production as closely as possible.
- `production.tfvars`: Live, customer-facing environment.

## Usage

To apply Terraform for a specific environment:

```sh
terraform apply -var-file="infra/environments/<env>.tfvars"
```

Replace `<env>` with `development`, `sandbox`, `staging`, or `production`.

## Promotion Flow

1. **Development**: Feature branches, local testing, and integration.
2. **Sandbox**: Automated preview/QA, short-lived environments.
3. **Staging**: Manual QA, pre-release, production-like.
4. **Production**: Customer-facing, stable, audited.

All environments use a single AWS account by default, but can be split in the future by updating the variable files and backend configuration.

---

**Note:** Keep secrets and sensitive values in a secure secrets manager, not in these files.
