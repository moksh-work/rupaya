# AWS Deployment Guide - Production Ready

Comprehensive guide for deploying Rupaya to AWS with industry best practices used by Stripe, Netflix, and Uber.

## Overview

```
GitHub Repository
    ↓
Commit to main/develop
    ↓
Automated Tests & Security Scans
    ↓
Build & Push to ECR
    ↓
Deploy to AWS ECS (Staging) / AWS ECS (Production)
    ↓
RDS Migrations
    ↓
Health Checks & Monitoring
    ↓
Slack Notifications
```

## AWS Architecture

### Production Environment
```
Internet
    ↓
Route 53 (DNS)
    ↓
CloudFront (CDN)
    ↓
ALB (Application Load Balancer)
    ↓
ECS Cluster (EC2/Fargate)
    ├── Backend Service (3 tasks minimum)
    ├── Redis Cache (ElastiCache)
    └── RDS PostgreSQL (Multi-AZ)
    ↓
S3 (File Storage)
CloudWatch (Monitoring)
```

### Staging Environment (identical, smaller scale)
```
Route 53 (DNS)
    ↓
ALB
    ↓
ECS Cluster
    ├── Backend Service (1 task)
    └── RDS PostgreSQL (Single-AZ)
```

## Services & Configuration

### 1. AWS ECR (Elastic Container Registry)

**Staging Repository:**
```
Account ID: 123456789012
Repository: rupaya-backend-staging
URI: 123456789012.dkr.ecr.us-east-1.amazonaws.com/rupaya-backend-staging
Retention Policy: 30 days (keep last 10 images)
```

**Production Repository:**
```
Account ID: 123456789012
Repository: rupaya-backend-prod
URI: 123456789012.dkr.ecr.us-east-1.amazonaws.com/rupaya-backend-prod
Retention Policy: 90 days (keep last 50 images)
Image Scanning: Enabled
```

### 2. AWS ECS (Elastic Container Service)

#### Staging Configuration
```
Cluster: rupaya-ecs-staging
Service: rupaya-backend-staging
Task Definition: rupaya-backend-staging:latest
Desired Tasks: 1
Min Tasks: 1
Max Tasks: 2

Task Configuration:
- CPU: 512
- Memory: 1024 MB
- Environment: staging
```

#### Production Configuration
```
Cluster: rupaya-ecs-prod
Service: rupaya-backend-prod
Task Definition: rupaya-backend-prod:latest
Desired Tasks: 3
Min Tasks: 3
Max Tasks: 10

Task Configuration:
- CPU: 1024
- Memory: 2048 MB
- Environment: production

Auto-scaling Policy:
- Scale up if CPU > 70%
- Scale down if CPU < 30%
```

### 3. AWS RDS (Relational Database Service)

#### Staging Database
```
Instance: rupaya-staging
Engine: PostgreSQL 15
Instance Type: db.t4g.medium
Storage: 100 GB, gp3
Multi-AZ: Disabled
Backups: 7 days
```

#### Production Database
```
Instance: rupaya-prod
Engine: PostgreSQL 15
Instance Type: db.r6g.large
Storage: 500 GB, io2
Multi-AZ: Enabled (sync standby)
Backups: 30 days
Enhanced Monitoring: Enabled
Performance Insights: Enabled
```

### 4. AWS ElastiCache (Redis)

#### Production
```
Engine: Redis 7.x
Instance Type: cache.r6g.large
Number of Nodes: 3 (cluster mode enabled)
Automatic Failover: Enabled
Multi-AZ: Enabled
Backup & Restore: Enabled
```

### 5. AWS Secrets Manager

Store these secrets in AWS Secrets Manager:

```json
{
  "db_password": "***",
  "jwt_secret": "***",
  "refresh_token_secret": "***",
  "sendgrid_api_key": "***",
  "plaid_client_id": "***",
  "plaid_secret": "***",
  "hibp_api_key": "***",
  "sentry_dsn": "***"
}
```

Rotation Policy: 90 days

### 6. Route 53 (DNS)

```
Production:
  api.rupaya.com → ALB (prod)
  staging-api.rupaya.com → ALB (staging)

Health Checks:
  Path: /health
  Port: 3000
  Interval: 30 seconds
  Failure threshold: 3
```

### 7. CloudWatch Monitoring

#### Key Metrics to Monitor
```
ECS:
- CPU Utilization
- Memory Utilization
- Task Count
- Service Deployments

RDS:
- CPU Utilization
- Database Connections
- Replication Lag (production)
- Storage Used

ElastiCache:
- CPU Utilization
- Evictions
- Network Bytes In/Out
```

#### Alarms
```
CRITICAL:
- ECS Service unhealthy: page on-call
- RDS CPU > 90%: page DBA
- Database connection pool exhausted

WARNING:
- ECS memory > 80%: notify team
- RDS storage > 80%: notify team
```

## Deployment Workflows

### Automated Workflows

#### 1. Backend Deployment to Staging
**Trigger:** Push to `develop` branch

```yaml
Flow:
- Run unit tests
- Run integration tests
- Security scan (SAST)
- Build Docker image
- Push to ECR (staging repo)
- Deploy to ECS (staging)
- Run smoke tests
- Notify Slack
```

#### 2. Backend Deployment to Production
**Trigger:** Push to `main` branch

```yaml
Flow:
- Run ALL tests (unit + integration)
- Security scan (SAST + dependency scan)
- Build Docker image
- Push to ECR (production repo)
- Require manual approval
- Deploy to ECS (production)
- Wait for service stability
- Run health checks
- Run smoke tests
- Notify Slack
- Create deployment record
```

#### 3. Database Migrations - Staging
**Trigger:** Changes to `backend/migrations/**`

```yaml
Flow:
- Validate SQL syntax
- Test migration (dry-run)
- Create backup
- Run migration on staging
- Verify migration
- Notify team
```

#### 4. Database Migrations - Production
**Trigger:** After staging migration succeeds

```yaml
Flow:
- Create backup (manual trigger recommended)
- Backup verification
- Run migration with monitoring
- Verify migration success
- Rollback plan ready
- Notify team on Slack
```

### Manual Deployment

**For emergency hotfixes:**

```bash
# 1. Create hotfix branch
git checkout -b hotfix/critical-security-fix main

# 2. Make fix and push
git push origin hotfix/critical-security-fix

# 3. Create PR with "URGENT" label
# → Expedited review (skip some checks)

# 4. Merge to main
# → Automatic production deployment

# 5. Also merge to develop
# → Keep staging in sync
```

## Deployment Checklist

### Before Every Production Deployment

- [ ] All tests passing in CI/CD
- [ ] Security scan passed (no high/critical issues)
- [ ] Database backup created
- [ ] Runbook reviewed and ready
- [ ] Team notified of deployment window
- [ ] Rollback plan documented
- [ ] Load testing completed (for major changes)

### Production Deployment Steps

1. **Pre-deployment**
   ```bash
   # Check current state
   aws ecs describe-services --cluster rupaya-ecs-prod --services rupaya-backend-prod
   
   # Enable detailed monitoring
   ```

2. **Deploy**
   ```bash
   # GitHub Actions automatically deploys
   # Or manual:
   aws ecs update-service --cluster rupaya-ecs-prod --service rupaya-backend-prod --force-new-deployment
   ```

3. **Monitor Deployment**
   ```bash
   # Watch deployment progress
   aws ecs wait services-stable --cluster rupaya-ecs-prod --services rupaya-backend-prod
   
   # Check CloudWatch for errors
   ```

4. **Post-deployment Verification**
   ```bash
   # Health check
   curl https://api.rupaya.com/health
   
   # Run smoke tests
   npm run test:smoke:production
   
   # Check metrics
   ```

5. **Rollback (if needed)**
   ```bash
   # Easy rollback to previous task definition
   aws ecs update-service \
     --cluster rupaya-ecs-prod \
     --service rupaya-backend-prod \
     --task-definition rupaya-backend-prod:PREVIOUS_VERSION
   ```

## Secrets Management

### GitHub Actions Secrets

Set in GitHub Settings → Secrets:

```
AWS_OIDC_ROLE_STAGING     # IAM role for staging
AWS_OIDC_ROLE_PROD        # IAM role for production
RDS_STAGING_USER          # Database user
RDS_STAGING_PASSWORD      # Database password
RDS_PROD_USER             # Database user
RDS_PROD_PASSWORD         # Database password
SLACK_WEBHOOK             # For notifications
```

### AWS Secrets Manager

Store application secrets in AWS Secrets Manager:
```
rupaya/staging/secrets    → Used by ECS task
rupaya/production/secrets → Used by ECS task
```

### Rotation

- Database credentials: 90 days
- JWT secrets: 180 days (with graceful old-key support)
- API keys: 180 days

## Cost Optimization

### Current Monthly Estimate (Production)
```
ECS (Fargate): $150
RDS (Multi-AZ): $300
ElastiCache: $200
Load Balancer: $20
Data Transfer: $50
Misc: $50
Total: ~$770/month
```

### Cost Saving Tips
1. Use Fargate Spot instances (30% cheaper)
2. Reserved capacity for baseline load
3. Scale down staging environment at night
4. Enable RDS automated backups (cheaper than manual)

## Troubleshooting

### Service won't start
```bash
# Check task logs
aws logs tail /ecs/rupaya-backend-prod --follow

# Verify environment variables
aws ecs describe-task-definition --task-definition rupaya-backend-prod

# Check ECR image
aws ecr describe-images --repository-name rupaya-backend-prod
```

### Database connection timeout
```bash
# Check RDS status
aws rds describe-db-instances --db-instance-identifier rupaya-prod

# Check security groups
aws ec2 describe-security-groups

# Verify credentials
```

### Deployment stuck
```bash
# Check service events
aws ecs describe-services --cluster rupaya-ecs-prod --services rupaya-backend-prod

# Force new deployment
aws ecs update-service --cluster rupaya-ecs-prod --service rupaya-backend-prod --force-new-deployment --no-paginate
```

## References

- [AWS ECS Best Practices](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-best-practices.html)
- [AWS RDS Best Practices](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_BestPractices.html)
- [AWS Secrets Manager](https://docs.aws.amazon.com/secretsmanager/latest/userguide/intro.html)
- [GitHub Actions AWS Authentication](https://github.com/aws-actions/configure-aws-credentials)

## Support

For deployment issues, contact:
- Slack: #rupaya-ops
- PagerDuty: On-call team
- Email: ops@rupaya.com
