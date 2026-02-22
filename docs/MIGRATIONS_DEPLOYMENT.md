# Automatic Database Migrations on Deployment

## Overview
Database migrations now run automatically when the backend is deployed to AWS using GitHub Actions. This ensures the database schema is always synchronized with the application code.

## How It Works

### 1. Docker Entrypoint Script
- **File**: `backend/docker-entrypoint.sh`
- Runs before the Node.js application starts
- Executes: `npm run migrate` (Knex migrations)
- If migrations fail, the container fails to start (prevents bad deployments)

### 2. Dockerfile Configuration
- **File**: `backend/Dockerfile`
- Production stage copies the entrypoint script
- Sets executable permissions: `chmod +x docker-entrypoint.sh`
- Uses dumb-init with the entrypoint script as the entry point
- ENTRYPOINT: `dumb-init -- ./docker-entrypoint.sh`
- CMD: `npm start`

### 3. Deployment Flow

#### GitHub Actions Workflow (08-aws-ecs-deploy.yml)
1. **Build Step**: Docker image is built with entrypoint script included
2. **Push Step**: Image is pushed to ECR with tags:
   - `v{run_number}-{short_sha}` (version tag)
   - `latest` (latest tag)
3. **Deploy Step**: ECS service is updated with new image

#### ECS Service Startup
1. ECS pulls the new image from ECR
2. Container starts with the entrypoint script
3. **Migrations Run**: `npm run migrate` executes
4. **Server Starts**: `npm start` runs after migrations complete
5. Health check begins after 10-second startup period

### 4. Migration Files
- **Location**: `backend/migrations/`
- Knex migrations run sequentially in order:
  - `001_init.js` - Initial schema
  - `002_add_phone_number_to_users.js` - Phone field
  - `003_complete_api_schema.sql` - Full API schema
  - `004_auth_token_revocation.sql` - Token revocation
  - `005_complete_transactions_table.sql` - Transactions table

## Deployment Scenarios

### Scenario 1: First Deployment
- Empty database tables don't exist
- Migrations create all necessary tables
- Application starts normally

### Scenario 2: Schema Update (migration file added)
- New migration file committed to `backend/migrations/`
- On next deployment, new migration runs automatically
- Existing tables are preserved, new ones are created

### Scenario 3: Deployment Rollback
- If old version is redeployed, migrations are idempotent
- Knex tracks applied migrations in `knex_migrations` table
- Previously-applied migrations are skipped

### Scenario 4: Failed Migration
- If a migration fails, container exits with error
- ECS health check fails
- Service doesn't mark task as healthy
- Application doesn't go live (prevents bad deploy)

## GitHub Actions Configuration

### Updated Workflows
The following workflows have been updated to use the correct AWS account (590184132516):
- `08-aws-ecs-deploy.yml` - Main ECS deployment
- `05-common-backend-cicd.yml` - Backend CI/CD
- `06-terraform-infrastructure.yml` - Terraform apply
- `09-aws-deploy-staging.yml` - Staging deployment
- `10-aws-deploy-production.yml` - Production deployment

### Deployment Trigger
Push to `main` branch with changes in `backend/` folder:
```bash
git add backend/
git commit -m "Update: Add migration for new feature"
git push origin main
```

This automatically:
1. Runs tests
2. Builds Docker image
3. Pushes to ECR
4. Updates ECS service
5. **Runs migrations automatically**
6. Application goes live with new schema

## Monitoring Migrations

### CloudWatch Logs
- **Log Group**: `/ecs/rupaya-backend`
- **Log Stream**: `ecs/rupaya-backend/{task-id}`
- **Filter**: `Running database migrations` logs show migration output

### ECS Task Logs
```bash
aws logs tail /ecs/rupaya-backend --follow --filter-pattern="migration"
```

### Example Output
```
Running database migrations...
> rupaya-backend@1.0.0 migrate
> knex migrate:latest

Using environment: production
Batch 1 run: 3 migrations
✓ 001_init.js
✓ 002_add_phone_number_to_users.js  
✓ 003_complete_api_schema.sql

Starting server...
```

## Troubleshooting

### Migrations Fail to Apply
1. Check ECS task logs in CloudWatch
2. Verify migration file syntax
3. Check database connectivity in ECS task definition
4. Review RDS security group allows ECS access

### Migrations Already Applied
If you manually run migrations and then deploy:
- Knex skips already-applied migrations
- No duplicate application
- Safe to redeploy

### Manual Migration (if needed)
```bash
# On local machine with AWS credentials
cd backend
DB_HOST=rupaya-postgres.c5y6yssse23v.us-east-1.rds.amazonaws.com \
DB_NAME=rupaya \
DB_USER=rupaya \
DB_PASSWORD=$(aws secretsmanager get-secret-value --secret-id rupaya/db/password --query SecretString --output text) \
DB_SSL=true \
npm run migrate
```

## Best Practices

1. **Test Migrations Locally**
   ```bash
   cd backend
   npm run migrate:test
   ```

2. **Use Descriptive Migration Names**
   - File naming: `NNN_feature_description.js`
   - Example: `006_add_user_preferences_table.js`

3. **Keep Migrations Simple**
   - One logical change per migration
   - Avoid long-running operations
   - Test rollback if possible

4. **Review Before Commit**
   ```bash
   # Dry run migrations locally first
   npm run migrate -- --dry-run
   ```

5. **Monitor After Deployment**
   - Watch CloudWatch logs during deployment
   - Verify health checks pass
   - Confirm application responds to API calls
   - Check database queries work

## Related Files
- [docker-entrypoint.sh](../backend/docker-entrypoint.sh) - Entrypoint script
- [Dockerfile](../backend/Dockerfile) - Container configuration
- [knexfile.js](../backend/knexfile.js) - Knex configuration
- [migrations/](../backend/migrations/) - Migration files
