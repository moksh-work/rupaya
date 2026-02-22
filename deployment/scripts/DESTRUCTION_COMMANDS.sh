#!/bin/bash

# AWS Infrastructure Destruction - Quick Reference Guide
# 
# This file contains quick commands for common destruction scenarios.
# Copy and paste as needed.

# ============================================================================
# SCENARIO 1: Destroy Development Infrastructure Only
# ============================================================================
# Use case: Cleaning up dev environment between sprints
# Time: 5-10 minutes
# Risk: Low (dev environment)

# Step 1: Validate resources
python3 deployment/scripts/pre-destroy-validator.py --verbose

# Step 2: Run destruction
./deployment/scripts/destroy-infrastructure.sh --dev

# Result: deployment/terraform dev configuration destroyed


# ============================================================================
# SCENARIO 2: Destroy Entire Infrastructure (Prod + Dev + Infra)
# ============================================================================
# Use case: Complete teardown of all AWS resources
# Time: 15-30 minutes
# Risk: High (includes production)

# Step 1: Backup state files (critical!)
mkdir -p terraform-state-backup-$(date +%Y%m%d)
cp -r infra/aws/.terraform* terraform-state-backup-$(date +%Y%m%d)/
cp -r deployment/terraform/.terraform* terraform-state-backup-$(date +%Y%m%d)/
cp infra/aws/terraform.tfstate* terraform-state-backup-$(date +%Y%m%d)/ 2>/dev/null || true
cp deployment/terraform/terraform.tfstate* terraform-state-backup-$(date +%Y%m%d)/ 2>/dev/null || true

# Step 2: Pre-dissolution checks (show what will be deleted)
python3 deployment/scripts/pre-destroy-validator.py --export pre-destroy-report.json --verbose

# Step 3: Review pre-destroy report
cat pre-destroy-report.json | jq '.results[] | select(.status=="PASSED")'

# Step 4: Run full destruction with confirmations
./deployment/scripts/destroy-infrastructure.sh --all

# Result: All infrastructure destroyed, logs saved in deployment/scripts/logs/


# ============================================================================
# SCENARIO 3: Destroy Infra/AWS Only (Keep Deployment Config)
# ============================================================================
# Use case: Recreate just the base infrastructure
# Time: 5-10 minutes
# Risk: Medium (base infrastructure)

# Step 1: Validate
python3 deployment/scripts/pre-destroy-validator.py

# Step 2: Destroy only infra/aws
./deployment/scripts/destroy-infrastructure.sh --infra

# Result: Only infra/aws destroyed, deployment/terraform remains intact


# ============================================================================
# SCENARIO 4: Quick Destruction with Auto-Confirmation
# ============================================================================
# Use case: Automated cleanup (CI/CD pipeline, etc.)
# Time: 15-30 minutes
# Risk: Very High (no human confirmation)

# Step 1: Check for any uncommitted changes
git status

# Step 2: Auto-destroy all with verbose logging
./deployment/scripts/destroy-infrastructure.sh --all --confirm --verbose

# Result: All infrastructure destroyed without prompts


# ============================================================================
# SCENARIO 5: Cleanup Failed Destruction
# ============================================================================
# Use case: Resume after interruption or failure
# Time: Varies
# Risk: High (manual cleanup)

# Step 1: Check what resources still exist
aws ec2 describe-instances --region us-east-1 --query 'Reservations[].Instances[].[InstanceId,State.Name,Tags[?Key==`Name`].Value|[0]]'
aws rds describe-db-instances --region us-east-1 --query 'DBInstances[].[DBInstanceIdentifier,DBInstanceStatus]'
aws elasticache describe-replication-groups --region us-east-1 --query 'ReplicationGroups[].[ReplicationGroupId,Status]'

# Step 2: Review logs to understand what failed
tail -100 deployment/scripts/logs/destroy_*.log

# Step 3: If resources exist, run destruction script again
./deployment/scripts/destroy-infrastructure.sh --all --verbose

# Step 4: If specific resources won't delete, investigate individually
# Example: RDS database won't delete
aws rds describe-db-instances --db-instance-identifier rupaya-postgres --query 'DBInstances[0]'

# Step 5: Manual cleanup if needed (last resort)
# BE CAREFUL: This manually deletes resources
aws rds delete-db-instance --db-instance-identifier rupaya-postgres --skip-final-snapshot --region us-east-1


# ============================================================================
# SCENARIO 6: Dry-Run (See What Would be Destroyed)
# ============================================================================
# Use case: Preview destruction without executing
# Time: 1-2 minutes
# Risk: None (no actual changes)

# Step 1: Show Terraform destruction plan
cd infra/aws
terraform plan -destroy

cd ../../deployment/terraform
terraform plan -destroy

# Step 2: Review the plan carefully for any unexpected resources

# Step 3: Run actual destruction when ready


# ============================================================================
# SCENARIO 7: Selective Resource Removal
# ============================================================================
# Use case: Delete specific resources, keep others
# Time: 5-15 minutes (varies)
# Risk: Medium (selective deletion)

# Step 1: List specific resource in Terraform state
cd infra/aws
terraform state list | grep "aws_rds"    # List all RDS resources
terraform state list | grep "aws_ecr"    # List all ECR resources

# Step 2: Remove specific resource from state
terraform state rm 'aws_db_instance.postgres'

# Step 3: Plan destruction to see what changed
terraform plan -destroy

# Step 4: Apply destruction
terraform destroy -target='aws_db_instance.postgres'


# ============================================================================
# MANUAL VERIFICATION COMMANDS
# ============================================================================

# List all EC2 instances
aws ec2 describe-instances --query 'Reservations[].Instances[].InstanceId' --region us-east-1

# List all RDS databases
aws rds describe-db-instances --query 'DBInstances[].DBInstanceIdentifier' --region us-east-1

# List all ElastiCache clusters
aws elasticache describe-replication-groups --query 'ReplicationGroups[].ReplicationGroupId' --region us-east-1

# List all ECR repositories
aws ecr describe-repositories --query 'repositories[].repositoryName' --region us-east-1

# List all VPCs
aws ec2 describe-vpcs --query 'Vpcs[].[VpcId,Tags[?Key==`Name`].Value|[0]]' --region us-east-1

# List all security groups
aws ec2 describe-security-groups --query 'SecurityGroups[?GroupName!=`default`].[GroupId,GroupName]' --region us-east-1

# List all IAM roles
aws iam list-roles --query 'Roles[?contains(RoleName, `rupaya`) || contains(RoleName, `terraform`)].RoleName'

# List all Route53 hosted zones
aws route53 list-hosted-zones --query 'HostedZones[].[Id,Name]'


# ============================================================================
# LOGGING AND DEBUGGING
# ============================================================================

# Show latest logs
tail -f deployment/scripts/logs/destroy_*.log

# Search logs for errors
grep -i "error" deployment/scripts/logs/destroy_*.log

# Get summary of last destruction
grep -E "^\[.*\] (PASSED|FAILED|ERROR|SUCCESS)" deployment/scripts/logs/destroy_*.log | tail -20

# Export logs to file
cp deployment/scripts/logs/destroy_*.log ./destruction-logs-backup-$(date +%Y%m%d).txt

# Check specific timeouts
grep -i "timeout\|waiting\|still" deployment/scripts/logs/destroy_*.log


# ============================================================================
# SAFETY CHECKLIST
# ============================================================================

# Before running ANY destruction:
# [ ] Are you in the right AWS account? Check:
aws sts get-caller-identity | jq '.Account'

# [ ] Are you in the right region?
export AWS_REGION=$(aws configure get region)

# [ ] Is anyone using this infrastructure right now?
# Check with team members!

# [ ] Do you have backups of important data?
# Check RDS snapshots, S3 backups, etc.

# [ ] Is this the right environment?
# Double-check: you're destroying DEV/STAGING/PROD?

# [ ] Have you committed all work?
git status

# [ ] Did you take the terraform state backups?
ls -la terraform-state-backup-*/


# ============================================================================
# POST-DESTRUCTION VERIFICATION
# ============================================================================

# Verify all resources are deleted
python3 deployment/scripts/pre-destroy-validator.py --export post-destroy-report.json

# Check Terraform state is empty
terraform -chdir=infra/aws show | head -3
terraform -chdir=deployment/terraform show | head -3

# Verify in AWS console
# Go to: https://console.aws.amazon.com
# Check each service for any remaining resources

# Review logs for any errors or warnings
grep -i "error\|warning" deployment/scripts/logs/destroy_*.log | wc -l


# ============================================================================
# INTEGRATION EXAMPLES
# ============================================================================

# Use in Makefile
# .PHONY: destroy-all
# destroy-all:
#     $(SHELL) deployment/scripts/destroy-infrastructure.sh --all

# Use in GitHub Actions
# - name: Destroy Infrastructure
#   run: |
#     chmod +x deployment/scripts/destroy-infrastructure.sh
#     deployment/scripts/destroy-infrastructure.sh --all --confirm

# Use in GitLab CI
# destroy_infrastructure:
#   stage: cleanup
#   script:
#     - chmod +x deployment/scripts/destroy-infrastructure.sh
#     - ./deployment/scripts/destroy-infrastructure.sh --all --confirm


# ============================================================================
# RECOVERY PROCEDURES
# ============================================================================

# If Terraform state gets corrupted:
cd infra/aws
rm -rf .terraform
rm .terraform.lock.hcl
terraform init
terraform refresh

# If AWS resources remain after destruction:
# Option 1: Try running destruction again
./deployment/scripts/destroy-infrastructure.sh --all

# Option 2: Manual cleanup (use with extreme caution)
# Delete RDS database manually
aws rds delete-db-instance \
    --db-instance-identifier rupaya-postgres \
    --skip-final-snapshot \
    --region us-east-1

# Option 3: Check for stuck processes or locks
lsof | grep terraform
ps aux | grep terraform


# ============================================================================
# ADDITIONAL RESOURCES
# ============================================================================

# Full documentation
cat deployment/scripts/DESTRUCTION_GUIDE.md

# Run validator with all options
python3 deployment/scripts/pre-destroy-validator.py --help

# Get script help
./deployment/scripts/destroy-infrastructure.sh --help

# Terraform documentation
# https://www.terraform.io/docs/cli/commands/destroy.html

# AWS CLI documentation
# https://docs.aws.amazon.com/cli/latest/userguide/

# Project documentation
# See docs/DEPLOYMENT.md and docs/AWS_DEPLOYMENT_GUIDE.md
