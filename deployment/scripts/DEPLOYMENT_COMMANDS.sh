#!/bin/bash

# Rupaya Deployment - Quick Reference Guide
# 
# This file contains quick commands for common deployment scenarios.
# Copy and paste as needed.

# ============================================================================
# SCENARIO 1: Deploy Backend to Development
# ============================================================================
# Use case: Update backend application in dev environment
# Time: 5-10 minutes
# Risk: Low (development only)

# Step 1: Verify git is clean
git status

# Step 2: Build and deploy
./deployment/scripts/deploy.sh --environment dev --target backend

# Step 3: Verify health
curl https://dev-api.cloudycs.com/health

# Result: Latest backend deployed to dev ECS cluster


# ============================================================================
# SCENARIO 2: Deploy Entire Stack to Staging
# ============================================================================
# Use case: Push complete environment to staging
# Time: 15-25 minutes
# Risk: Medium (staging environment)

# Step 1: Run dry-run first
./deployment/scripts/deploy.sh --environment staging --target all --dry-run

# Step 2: Review what will be deployed
grep -i "would\|change" deployment/scripts/logs/deploy_*.log

# Step 3: Deploy with confirmations
./deployment/scripts/deploy.sh --environment staging --target all

# Step 4: Run smoke tests
cd backend && npm run test:smoke

# Result: Complete staging environment updated


# ============================================================================
# SCENARIO 3: Emergency Production Infrastructure Update
# ============================================================================
# Use case: Critical security patch/fix to AWS infrastructure
# Time: 10-20 minutes
# Risk: High (production infrastructure)

# Step 1: Backup current state
mkdir -p .emergency-backup-$(date +%Y%m%d_%H%M%S)
cd infra/aws && terraform state pull > ../../.emergency-backup-$(date +%Y%m%d_%H%M%S)/tfstate.json

# Step 2: Review changes
terraform plan

# Step 3: Announce to team
# "Production infrastructure update in progress"

# Step 4: Deploy infrastructure only
./deployment/scripts/deploy.sh --environment prod --target infra --confirm

# Step 5: Verify all services still running
aws ecs describe-services --cluster rupaya-prod --services rupaya-backend-prod | jq '.services[0].status'

# Step 6: Health checks
curl https://api.cloudycs.com/health

# Result: Infrastructure updated with zero downtime (hopefully!)


# ============================================================================
# SCENARIO 4: Patch Backend Version in Production
# ============================================================================
# Use case: Deploy hotfix or patch version to production
# Time: 5-10 minutes
# Risk: High (production application)

# Step 1: Tag version
git tag v1.2.3-hotfix
git push origin v1.2.3-hotfix

# Step 2: Run tests
npm run test

# Step 3: Deploy specific version
./deployment/scripts/deploy.sh \
  --environment prod \
  --target backend \
  --version v1.2.3-hotfix

# Step 4: Monitor logs
tail -f deployment/scripts/logs/deploy_*.log

# Step 5: Verify deployment
aws ecs describe-services \
  --cluster rupaya-prod \
  --services rupaya-backend-prod \
  --query 'services[0].deployments'

# Result: Hotfix deployed to production


# ============================================================================
# SCENARIO 5: Full Production Deployment (Planned Release)
# ============================================================================
# Use case: Major release to production
# Time: 30-45 minutes
# Risk: Very High (all production components)

# Step 1: Pre-deployment checklist
echo "Deployment Checklist:"
echo "[ ] Code reviewed and merged"
grep -q "prod" .env && echo "[✓] Right AWS account" || echo "[✗] WRONG ACCOUNT!"
echo "[ ] Database backups taken"
echo "[ ] Previous version known"
echo "[ ] Team notified"
echo "[ ] On-call engineer available"

# Step 2: Backup everything
mkdir -p .production-backup-$(date +%Y%m%d_%H%M%S)
cp -r infra/aws/.terraform* .production-backup-$(date +%Y%m%d_%H%M%S)/
aws rds create-db-snapshot --db-instance-identifier rupaya-postgres --db-snapshot-identifier backup-$(date +%Y%m%d-%H%M%S)

# Step 3: Dry-run to preview
./deployment/scripts/deploy.sh \
  --environment prod \
  --target all \
  --dry-run \
  --verbose

# Step 4: Review plan carefully
echo "Review plan? Press Enter to continue or Ctrl+C to cancel"
read

# Step 5: Deploy infrastructure if needed
./deployment/scripts/deploy.sh \
  --environment prod \
  --target infra \
  --confirm \
  --verbose

# Step 6: Deploy application and migrations
./deployment/scripts/deploy.sh \
  --environment prod \
  --target backend \
  --confirm \
  --verbose

# Step 7: Deploy frontend
./deployment/scripts/deploy.sh \
  --environment prod \
  --target frontend \
  --confirm \
  --verbose

# Step 8: Run post-deployment tests
cd backend && npm run test:production

# Step 9: Monitor for issues
tail -100 deployment/scripts/logs/deploy_*.log

# Step 10: Notify team
# "v1.2.3 deployed to production successfully"

# Result: Complete production deployment


# ============================================================================
# SCENARIO 6: Rollback Failed Production Deployment
# ============================================================================
# Use case: Previous deployment caused issues, need to revert
# Time: 10-20 minutes
# Risk: High (under pressure)

# Step 1: Stop the bleeding
echo "INCIDENT: Previous deployment causing issues"
echo "Rolling back to previous version..."

# Step 2: Check what went wrong
tail -200 deployment/scripts/logs/deploy_*.log | grep -i error

# Step 3: Rollback backend
aws ecs update-service \
  --cluster rupaya-prod \
  --service rupaya-backend-prod \
  --force-new-deployment

# Step 4: Wait for service to stabilize
echo "Waiting for service to stabilize..."
sleep 2m

# Step 5: Verify rollback
aws ecs describe-services \
  --cluster rupaya-prod \
  --services rupaya-backend-prod \
  --query 'services[0].deployments'

# Step 6: Health check
curl https://api.cloudycs.com/health

# Step 7: Post-mortem
# "Rollback completed. Investigating root cause..."

# Result: Previous version restored


# ============================================================================
# SCENARIO 7: Database Migration Verification
# ============================================================================
# Use case: Verify database schema changes after deployment
# Time: 5 minutes
# Risk: Low (read-only verification)

# Step 1: Check migration status
cd backend
npm run migrate:status-prod

# Step 2: List recent migrations
npm run migrate:list-prod | head -20

# Step 3: Verify data integrity
npm run test:db-integrity

# Step 4: Check database size
aws rds describe-db-instances \
  --db-instance-identifier rupaya-postgres \
  --query 'DBInstances[0].AllocatedStorage'

# Result: Database schema verified


# ============================================================================
# DRY-RUN MODE (Preview Without Changes)
# ============================================================================

# See what would be deployed WITHOUT making any changes
./deployment/scripts/deploy.sh \
  --environment dev \
  --target backend \
  --dry-run

# Full stack preview
./deployment/scripts/deploy.sh \
  --environment staging \
  --target all \
  --dry-run \
  --verbose


# ============================================================================
# VERBOSE LOGGING (Detailed Debug)
# ============================================================================

# Enable detailed logging for troubleshooting
./deployment/scripts/deploy.sh \
  --environment dev \
  --target backend \
  --verbose

# Watch real-time logs
tail -f deployment/scripts/logs/deploy_*.log


# ============================================================================
# VALIDATION AND VERIFICATION
# ============================================================================

# Pre-deployment validation only
./deployment/scripts/deploy.sh \
  --environment dev \
  --target backend \
  --skip-validation=false

# Skip backups (dangerous!)
./deployment/scripts/deploy.sh \
  --environment dev \
  --target backend \
  --skip-backup

# Skip confirmation prompts (for CI/CD)
./deployment/scripts/deploy.sh \
  --environment dev \
  --target backend \
  --confirm


# ============================================================================
# AWS CLI VERIFICATION COMMANDS
# ============================================================================

# Check ECS service status
aws ecs describe-services \
  --cluster rupaya-dev \
  --services rupaya-backend-dev \
  --query 'services[0].[status,deployments]'

# View ECS service events
aws ecs describe-services \
  --cluster rupaya-dev \
  --services rupaya-backend-dev \
  --query 'services[0].events[0:5]'

# List ECS tasks
aws ecs list-tasks --cluster rupaya-dev

# View task logs
aws logs tail /ecs/rupaya-backend-dev --follow

# Check RDS status
aws rds describe-db-instances \
  --db-instance-identifier rupaya-postgres \
  --query 'DBInstances[0].DBInstanceStatus'

# Check ElastiCache status
aws elasticache describe-replication-groups \
  --replication-group-id rupaya-redis \
  --query 'ReplicationGroups[0].Status'


# ============================================================================
# LOGGING AND MONITORING
# ============================================================================

# View latest deployment logs
tail -100 deployment/scripts/logs/deploy_*.log

# Search for errors
grep -i "error\|failed" deployment/scripts/logs/deploy_*.log

# Watch deployment progress
tail -f deployment/scripts/logs/deploy_*.log

# Get deployment summary
grep -E "^\[.*\] (Starting|completed|✓|✗)" deployment/scripts/logs/deploy_*.log | tail -20

# Export logs for analysis
cp deployment/scripts/logs/deploy_*.log ./deployment-logs-backup-$(date +%Y%m%d).txt


# ============================================================================
# BACKUP AND RECOVERY
# ============================================================================

# View state file backups
ls -la .state-backups/

# List backup contents
ls -la .state-backups/backup_DATE/

# Restore from backup
cp .state-backups/backup_DATE/terraform.tfstate infra/aws/
cd infra/aws && terraform refresh

# Create manual backup
mkdir -p .state-backups/manual-backup-$(date +%Y%m%d_%H%M%S)
cp infra/aws/terraform.tfstate .state-backups/manual-backup-$(date +%Y%m%d_%H%M%S)/


# ============================================================================
# ENVIRONMENT-SPECIFIC COMMANDS
# ============================================================================

# DEVELOPMENT
./deployment/scripts/deploy.sh --environment dev --target backend
./deployment/scripts/deploy.sh --environment dev --target all --dry-run

# STAGING
./deployment/scripts/deploy.sh --environment staging --target backend --confirm
./deployment/scripts/deploy.sh --environment staging --target all --confirm

# PRODUCTION
./deployment/scripts/deploy.sh --environment prod --target backend
./deployment/scripts/deploy.sh --environment prod --target infra --verbose
./deployment/scripts/deploy.sh --environment prod --target all --confirm --verbose


# ============================================================================
# SAFETY CHECKLIST BEFORE EACH DEPLOYMENT
# ============================================================================

# Are you in the right environment?
aws sts get-caller-identity | jq '.Account'

# Are you deploying the right target?
echo "Deploying: infra | backend | frontend | all?"

# Do you know how to rollback?
echo "Rollback procedure: [know it or don't deploy]"

# Is the team aware?
echo "Team notification sent? [yes | no]"

# Do you have logs running?
tail -f deployment/scripts/logs/deploy_*.log &

# Is git clean?
git status

# Did you review the changes?
git diff HEAD~1..HEAD | head -50


# ============================================================================
# INTEGRATION EXAMPLES
# ============================================================================

# Use in Makefile
# .PHONY: deploy-backend-dev
# deploy-backend-dev:
#     ./deployment/scripts/deploy.sh --environment dev --target backend

# Use in GitHub Actions
# - name: Deploy
#   run: |
#     chmod +x deployment/scripts/deploy.sh
#     ./deployment/scripts/deploy.sh --environment ${{ env.DEPLOY_ENV }} --target ${{ env.DEPLOY_TARGET }} --confirm

# Use in Cron/Scheduled Job
# 0 2 * * * cd /path/to/rupaya && ./deployment/scripts/deploy.sh --environment dev --target backend --confirm >> deploy.cron.log 2>&1

# Use in Docker container
# docker run -v $(pwd):/workspace rupaya-tools:latest deployment/scripts/deploy.sh --environment dev --target backend


# ============================================================================
# ADDITIONAL RESOURCES
# ============================================================================

# Full documentation
cat deployment/scripts/DEPLOYMENT_GUIDE.md

# Get script help
./deployment/scripts/deploy.sh --help

# Check logs
tail -50 deployment/scripts/logs/deploy_*.log

# Infrastructure destruction (if needed)
./deployment/scripts/destroy-infrastructure.sh --help

# Related AWS documentation
# https://docs.aws.amazon.com/ecs/latest/developerguide/task_definition_parameters.html
# https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/
# https://docs.aws.amazon.com/ElastiCache/latest/red-ug/
