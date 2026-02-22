# AWS Infrastructure Destruction Tool

Comprehensive toolkit for safely destroying AWS infrastructure with built-in safeguards, validation, and automatic issue resolution.

## Overview

This tool suite provides:

- **Automated Destruction Script**: Safely destroys AWS infrastructure across multiple Terraform configurations
- **Pre-Destruction Validator**: Validates resources and prerequisites before destruction
- **Issue Resolution**: Automatically fixes common Terraform issues encountered during destruction
- **Resource Cleanup**: Handles edge cases like non-empty ECR repositories
- **Comprehensive Logging**: Detailed logs for audit trail and debugging
- **Confirmation Workflow**: Multi-step confirmation process for safety

## Components

### 1. Main Destruction Script (`destroy-infrastructure.sh`)

The primary script that orchestrates infrastructure destruction.

#### Features
- Multi-step destruction with validation at each stage
- Automatic ECR image cleanup
- Terraform configuration issue fixes
- Pre-checks for AWS credentials and tools
- Comprehensive error handling and logging
- Progress tracking with detailed output
- Rollback information in logs

#### Usage

```bash
# Make script executable
chmod +x deployment/scripts/destroy-infrastructure.sh

# View help
./deployment/scripts/destroy-infrastructure.sh --help

# Destroy infra/aws only
./deployment/scripts/destroy-infrastructure.sh --infra

# Destroy deployment/terraform only (prod/dev)
./deployment/scripts/destroy-infrastructure.sh --prod
./deployment/scripts/destroy-infrastructure.sh --dev

# Destroy ALL infrastructure
./deployment/scripts/destroy-infrastructure.sh --all

# Skip confirmation prompts (use with extreme caution)
./deployment/scripts/destroy-infrastructure.sh --all --confirm

# Enable verbose logging
./deployment/scripts/destroy-infrastructure.sh --all --verbose
```

#### Command Flags

| Flag | Description |
|------|-------------|
| `-a, --all` | Destroy all infrastructure (prod + dev + infra) |
| `-p, --prod` | Destroy production infrastructure only |
| `-d, --dev` | Destroy development infrastructure only |
| `-i, --infra` | Destroy /infra/aws infrastructure only |
| `-c, --confirm` | Skip confirmation prompts (be careful!) |
| `-v, --verbose` | Enable verbose logging for debugging |
| `-h, --help` | Display help message |

#### Examples

```bash
# Safe destruction with confirmations
./deployment/scripts/destroy-infrastructure.sh --infra

# Quick destruction of everything (requires confirmation)
./deployment/scripts/destroy-infrastructure.sh --all --confirm

# Development environment only
./deployment/scripts/destroy-infrastructure.sh --dev --verbose
```

#### Destruction Flow

1. **Banner Display**: Shows warning about permanent deletion
2. **Argument Parsing**: Validates command-line arguments
3. **Target Confirmation**: Shows what will be destroyed
4. **User Confirmation**: Requires explicit confirmation
5. **Safety Wait**: 3-second pause before starting (Ctrl+C to cancel)
6. **For each target**:
   - AWS credentials verification
   - Terraform dependency fixes
   - Terraform initialization
   - Configuration validation
   - ECR image cleanup (if applicable)
   - Resource destruction
   - State verification
7. **Summary Report**: Final status of destruction

### 2. Pre-Destruction Validator (`pre-destroy-validator.py`)

Python script to validate resources and permissions before destruction.

#### Features
- AWS credentials validation
- Tool installation checks
- Resource inventory (ECR, RDS, ElastiCache, IAM)
- Dependency analysis
- Detailed reporting
- JSON export for integration

#### Usage

```bash
# Make script executable
chmod +x deployment/scripts/pre-destroy-validator.py

# Run checks for default region
python3 deployment/scripts/pre-destroy-validator.py

# Specify AWS region
python3 deployment/scripts/pre-destroy-validator.py --region us-west-2

# Enable verbose output
python3 deployment/scripts/pre-destroy-validator.py --verbose

# Export report to file
python3 deployment/scripts/pre-destroy-validator.py --export report.json
```

#### Validation Checks

| Check | Purpose |
|-------|---------|
| AWS Credentials | Verify AWS access is available |
| Terraform Installation | Ensure Terraform CLI is installed |
| AWS CLI Installation | Ensure AWS CLI is installed |
| ECR Repositories | Inventory Docker images |
| RDS Databases | List databases that will be deleted |
| ElastiCache Clusters | List Redis/Memcached clusters |
| IAM Resources | Find project-related IAM roles |

#### Sample Output

```
======================================================================
AWS Infrastructure Pre-Destruction Validation Report
Timestamp: 2026-02-18T10:30:45.123456
======================================================================

✓ AWS Credentials
  Credentials valid - Account: 590184132516, User: arn:aws:iam::590184132516:user/admin

✓ Terraform Installation
  Terraform installed - Terraform v1.5.0

✓ AWS CLI Installation
  AWS CLI installed - aws-cli/2.13.0

✓ ECR Repositories
  Found 1 repositories with 5 total images

✓ RDS Databases
  Found 1 RDS database(s)

✓ ElastiCache Clusters
  Found 1 ElastiCache cluster(s)

✓ IAM Resources
  Found 2 project-related IAM role(s)

======================================================================
Summary: 7 passed, 0 failed, 0 warnings
======================================================================
```

### 3. Configuration File (`destroy-config.conf`)

Centralized configuration for destruction parameters.

#### Key Settings

```bash
# AWS Configuration
AWS_REGIONS=("us-east-1" "us-west-2")
DEFAULT_REGION="us-east-1"

# Resource Cleanup
ECR_CLEANUP_ENABLED=true
RDS_SKIP_FINAL_SNAPSHOT=true
BACKUP_STATE_FILES=true

# Safety Configuration
REQUIRE_CONFIRMATION=true
STOP_ON_ERROR=true

# Service Timeouts
RDS_CLEANUP_TIMEOUT=600
ELASTICACHE_CLEANUP_TIMEOUT=300
```

## Issues Handled

### 1. Terraform Dependency Lock File

**Problem**: `.terraform.lock.hcl` inconsistencies
**Solution**: Automatically runs `terraform init -upgrade`

### 2. Undeclared Resource References

**Problem**: github-oidc.tf references undefined resources
**Solution**: Automatically fixes references by hardcoding bucket/table names

### 3. Non-Empty ECR Repositories

**Problem**: ECR won't delete if it contains images
**Solution**: Automatically deletes all images before destroying repository

### 4. RDS Database Snapshots

**Problem**: RDS deletion requires final snapshot handling
**Solution**: Configured to skip final snapshot during destruction (configurable)

### 5. Dependency Ordering

**Problem**: Resources with dependencies must be destroyed in correct order
**Solution**: Destruction order is configured in setup step

## Log Files

Log files are created in `deployment/scripts/logs/` with timestamp:

```
logs/
├── destroy_20260218_102030.log    # Main destruction log
├── destroy_20260218_103045.log    # Another destruction run
└── ...
```

### Log Contents
- Timestamp for each operation
- AWS resource IDs and status
- Terraform plan and destruction details
- Error messages and recovery actions
- Final summary with resource counts

## Interrupted Destruction Recovery

If destruction is interrupted:

1. **Check logs**: `tail -f deployment/scripts/logs/destroy_*.log`
2. **Verify state**: `terraform show` in relevant directories
3. **Resume**: Run script again - it will continue from where it left off
4. **Manual cleanup**: Check AWS console for leaked resources

## Common Issues and Solutions

### Issue: "AWS credentials not configured"
```bash
# Solution: Configure AWS credentials
aws configure
# or
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
```

### Issue: "Terraform not installed"
```bash
# Solution: Install Terraform
brew install terraform       # macOS
apt-get install terraform    # Ubuntu
choco install terraform      # Windows
```

### Issue: "Permission denied on script"
```bash
# Solution: Make script executable
chmod +x deployment/scripts/destroy-infrastructure.sh
chmod +x deployment/scripts/pre-destroy-validator.py
```

### Issue: Resource still exists after destruction
```bash
# Solution: Check logs and manually verify
tail -50 deployment/scripts/logs/destroy_*.log

# Check AWS resources directly
aws ec2 describe-instances --region us-east-1
aws rds describe-db-instances --region us-east-1
aws elasticache describe-replication-groups --region us-east-1
```

### Issue: "DynamoDB table error during init"
```bash
# Solution: Already handled by script - it hardcodes table name
# Manual fix if needed:
cd infra/aws
sed -i 's/${aws_dynamodb_table.terraform_lock.name}/rupaya-terraform-state-lock/g' github-oidc.tf
terraform init -upgrade
```

## Pre-Destruction Checklist

Before running destruction script:

- [ ] Ensure RDS databases are backed up (outside of this tool)
- [ ] Verify no production workloads are running
- [ ] Confirm team is aware of destruction
- [ ] Have AWS console access for verification
- [ ] Set aside time (destruction can take 5-15 minutes)
- [ ] Review and export any needed logs/data
- [ ] Disable any monitoring/alerting

## Post-Destruction Verification

After destruction completes:

```bash
# Verify Terraform state is empty
cd infra/aws && terraform show | head -5
cd ../deployment/terraform && terraform show | head -5

# Check AWS for orphaned resources
aws ec2 describe-instances --query 'Reservations[].Instances[].InstanceId' --region us-east-1
aws rds describe-db-instances --query 'DBInstances[].DBInstanceIdentifier' --region us-east-1
aws elasticache describe-replication-groups --query 'ReplicationGroups[].ReplicationGroupId' --region us-east-1
```

## Customization

### Extending the Script

To add custom pre-destruction checks:

```bash
# Add function to destroy-infrastructure.sh
custom_check() {
    log_info "Running custom check..."
    # Your validation logic here
    if [[ condition ]]; then
        log_success "Custom check passed"
        return 0
    else
        log_error "Custom check failed"
        return 1
    fi
}

# Add to main() before destruction
if ! custom_check; then
    log_error "Custom checks failed"
    exit 1
fi
```

### Modified Timeout Values

Edit `destroy-config.conf`:

```bash
SERVICE_CLEANUP_TIMEOUTS=(
    ["rds"]=900           # Increase from 600 to 900 seconds
    ["elasticache"]=600   # Increase timeout
)
```

## Security Considerations

1. **Credentials**: Never commit AWS credentials to repository
2. **Logs**: Logs contain resource IDs - keep them secure
3. **State Files**: Terraform state files contain sensitive data
4. **Audit Trail**: All operations are logged for compliance
5. **Backups**: Ensure backups are taken before destruction

## Performance

Typical destruction times:

- **Small environment** (dev): 5-10 minutes
- **Medium environment**: 10-15 minutes
- **Large environment** (prod): 15-30 minutes

Factors affecting speed:
- Database size (larger = longer to delete)
- Number of resources
- AWS API rate limits
- Network connectivity

## Troubleshooting

### Enable Debug Mode

```bash
# In destroy-infrastructure.sh
VERBOSE=true
DEBUG_PRINT_COMMANDS=true

# Run script
./destroy-infrastructure.sh --infra --verbose
```

### Check Terraform State

```bash
cd /path/to/terraform/config
terraform state list     # List all resources
terraform state show     # Show detailed state
terraform show          # Show planned changes
```

### View AWS Resources

```bash
# List all resources by type
aws ec2 describe-instances --region us-east-1
aws rds describe-db-instances --region us-east-1
aws elasticache describe-replication-groups --region us-east-1
aws ecr describe-repositories --region us-east-1
aws elbv2 describe-load-balancers --region us-east-1
```

## Support

For issues or questions:

1. Check logs: `deployment/scripts/logs/destroy_*.log`
2. Run validator: `python3 deployment/scripts/pre-destroy-validator.py --verbose`
3. Review Terraform state: `terraform state list`
4. Verify AWS resources: Use AWS console

## Version History

- **v1.0** (2026-02-18): Initial release
  - Core destruction functionality
  - ECR image cleanup
  - Terraform issue fixes
  - Pre-destruction validation
