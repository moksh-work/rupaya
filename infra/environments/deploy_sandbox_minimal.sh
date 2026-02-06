#!/bin/bash
# Manual deployment script for minimal sandbox infrastructure
# Usage: ./deploy_sandbox_minimal.sh

set -euo pipefail
cd "$(dirname "$0")"

TF_VAR_FILE="sandbox.auto.tfvars"
TF_MINIMAL_FILE="sandbox_minimal.tf"

if [ ! -f "$TF_VAR_FILE" ]; then
  echo "ERROR: $TF_VAR_FILE not found. Copy and edit sandbox.auto.tfvars.example first."
  exit 1
fi

# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Plan deployment
terraform plan -var-file="$TF_VAR_FILE" -out=tfplan -target=module.network -target=module.db

# Apply deployment
terraform apply "tfplan"

echo "\nDeployment complete. Review outputs above."
