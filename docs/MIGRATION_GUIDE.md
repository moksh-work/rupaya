# Project Migration Guide: Rename "rupaya" to "neev"

## Overview

This guide enables easy migration of the entire Rupaya project to a new name and repository. The process is **99% scriptable** due to project structure.

## What Gets Renamed

### AWS Infrastructure (Configuration-Based)
- ECR Repository: `rupaya-backend` → `neev-backend`
- ECS Cluster: `rupaya-ecs` → `neev-ecs`
- ECS Service: `rupaya-backend` → `neev-backend`
- Load Balancer: `rupaya-alb` → `neev-alb`
- CloudWatch Logs: `/ecs/rupaya-backend` → `/ecs/neev-backend`
- Route53 DNS: `api.rupaya.local` → `api.neev.local`
- Terraform: `project_name` variable in `terraform.tfvars`

### Code & Configuration Files
- iOS: Package prefix `com.rupaya` → `com.neev`
- Android: Package prefix `com.rupaya` → `com.neev`
- Backend: npm package name
- Terraform variable: `project_name = "rupaya"` → `project_name = "neev"`
- GitHub Actions: Hardcoded names in workflow
- Deployment scripts: Hardcoded ECR/ECS names

### Documentation
- All markdown files and comments
- README, guides, setup instructions

## Migration Steps

### Step 1: Create Parameterized Configuration File

Create a new file to centralize all naming:

```bash
# Create config file
cat > PROJECT_CONFIG.sh << 'EOF'
#!/bin/bash

# Project naming configuration
PROJECT_NAME="neev"          # Core project name
OLD_PROJECT_NAME="rupaya"    # Previous name (for find/replace)

# AWS Resources
ECR_REPOSITORY="${PROJECT_NAME}-backend"
ECS_CLUSTER="${PROJECT_NAME}-ecs"
ECS_SERVICE="${PROJECT_NAME}-backend"
ALB_NAME="${PROJECT_NAME}-alb"
CLOUDWATCH_LOG_GROUP="/ecs/${PROJECT_NAME}-backend"
ROUTE53_DOMAIN="api.${PROJECT_NAME}.local"

# Package names
iOS_PACKAGE="com.${PROJECT_NAME}"
ANDROID_PACKAGE="com.${PROJECT_NAME}"
BACKEND_NPM_PACKAGE="${PROJECT_NAME}-monorepo"

# AWS Account
AWS_ACCOUNT_ID="843976229340"
AWS_REGION="us-east-1"

# Display configuration
echo "📋 Project Configuration"
echo "================================"
echo "Project Name: $PROJECT_NAME"
echo "ECR Repo: $ECR_REPOSITORY"
echo "ECS Cluster: $ECS_CLUSTER"
echo "iOS Package: $iOS_PACKAGE"
echo "Android Package: $ANDROID_PACKAGE"
echo "API Domain: $ROUTE53_DOMAIN"
EOF

chmod +x PROJECT_CONFIG.sh
```

### Step 2: Automated Migration Script

Create a comprehensive migration script:

```bash
cat > scripts/migrate-project.sh << 'EOF'
#!/bin/bash

# Project migration script
# Usage: ./scripts/migrate-project.sh rupaya neev

set -e

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <old_name> <new_name>"
    echo "Example: $0 rupaya neev"
    exit 1
fi

OLD_NAME="$1"
NEW_NAME="$2"

# Validation
if [ -z "$OLD_NAME" ] || [ -z "$NEW_NAME" ]; then
    echo "❌ Names cannot be empty"
    exit 1
fi

if [ "$OLD_NAME" = "$NEW_NAME" ]; then
    echo "❌ Old and new names must be different"
    exit 1
fi

echo "🔄 Migrating project: $OLD_NAME → $NEW_NAME"
echo "================================================"

# 1. Find and replace in all files
echo "📝 Updating file contents..."

# Update shell scripts
echo "  • Deployment scripts..."
find . -name "*.sh" -type f ! -path "./.git/*" ! -path "./node_modules/*" \
    -exec sed -i '' "s/${OLD_NAME}/${NEW_NAME}/g" {} \;

# Update Python scripts
echo "  • Python scripts..."
find . -name "*.py" -type f ! -path "./.git/*" ! -path "./.venv/*" \
    -exec sed -i '' "s/${OLD_NAME}/${NEW_NAME}/g" {} \;

# Update Swift files (iOS)
echo "  • iOS Swift files..."
find ios -name "*.swift" -type f 2>/dev/null \
    -exec sed -i '' "s/${OLD_NAME}/${NEW_NAME}/g" {} \;

# Update Kotlin files (Android)
echo "  • Android Kotlin files..."
find android -name "*.kt" -type f 2>/dev/null \
    -exec sed -i '' "s/${OLD_NAME}/${NEW_NAME}/g" {} \;

# Update JavaScript/TypeScript files
echo "  • Backend files..."
find backend -name "*.js" -o -name "*.ts" -o -name "*.json" 2>/dev/null | grep -v node_modules | \
    xargs -I {} sed -i '' "s/${OLD_NAME}/${NEW_NAME}/g" {} \;

# Update Terraform files
echo "  • Terraform configuration..."
find infra -name "*.tf" -type f 2>/dev/null \
    -exec sed -i '' "s/${OLD_NAME}/${NEW_NAME}/g" {} \;

# Update Terraform vars
sed -i '' "s/project_name = \"${OLD_NAME}\"/project_name = \"${NEW_NAME}\"/" infra/aws/terraform.tfvars

# Update documentation
echo "  • Documentation files..."
find . -name "*.md" -type f ! -path "./.git/*" \
    -exec sed -i '' "s/${OLD_NAME}/${NEW_NAME}/g" {} \;

# Update YAML files (GitHub Actions)
echo "  • GitHub Actions workflows..."
find .github -name "*.yml" -o -name "*.yaml" 2>/dev/null | \
    xargs -I {} sed -i '' "s/${OLD_NAME}/${NEW_NAME}/g" {} \;

# Update Podfile (iOS)
if [ -f "ios/Podfile" ]; then
    echo "  • iOS Podfile..."
    sed -i '' "s/${OLD_NAME}/${NEW_NAME}/g" ios/Podfile
fi

# Update gradle files (Android)
echo "  • Android gradle files..."
find android -name "*.gradle" -o -name "build.gradle.kts" 2>/dev/null | \
    xargs -I {} sed -i '' "s/${OLD_NAME}/${NEW_NAME}/g" {} \;

# Update XML files (Android manifest)
echo "  • Android manifests..."
find android -name "AndroidManifest.xml" 2>/dev/null | \
    xargs -I {} sed -i '' "s/${OLD_NAME}/${NEW_NAME}/g" {} \;

# 2. Rename directories and files
echo ""
echo "📁 Renaming directories..."

# iOS
if [ -d "ios/${OLD_NAME^^}" ]; then
    NEW_NAME_UC=$(echo "$NEW_NAME" | tr '[:lower:]' '[:upper:]')
    mv "ios/${OLD_NAME^^}" "ios/${NEW_NAME_UC}"
    echo "  ✓ ios/${OLD_NAME^^} → ios/${NEW_NAME_UC}"
fi

# Android
if [ -d "android/app/src/main/kotlin/com/${OLD_NAME}" ]; then
    mv "android/app/src/main/kotlin/com/${OLD_NAME}" \
       "android/app/src/main/kotlin/com/${NEW_NAME}"
    echo "  ✓ android package: com.${OLD_NAME} → com.${NEW_NAME}"
fi

# 3. Update root directory name (optional)
echo ""
echo "📦 Project configuration updated"
echo "=================================="
echo "Old project name: $OLD_NAME"
echo "New project name: $NEW_NAME"
echo ""
echo "✅ Migration complete!"
echo ""
echo "📋 Next steps:"
echo "1. Verify all changes: git diff"
echo "2. Test local builds: npm run build:all"
echo "3. Commit changes: git add . && git commit -m 'Migration: $OLD_NAME → $NEW_NAME'"
echo "4. Create new repository with name: neev"
echo "5. Update git remote: git remote set-url origin <new-repo-url>"
echo "6. Deploy infrastructure: cd infra/aws && terraform apply"
echo ""
EOF

chmod +x scripts/migrate-project.sh
```

### Step 3: Run Migration

```bash
# From project root
./scripts/migrate-project.sh rupaya neev
```

**What this does:**
- ✅ Replaces all occurrences in code files
- ✅ Updates configuration files (Terraform, Gradle, Swift, Kotlin)
- ✅ Renames directories (`ios/RUPAYA` → `ios/NEEV`)
- ✅ Updates package names (`com.rupaya` → `com.neev`)
- ✅ Updates documentation
- ✅ Updates GitHub Actions workflows
- ✅ Preserves `.git` directory and node_modules

### Step 4: AWS Infrastructure Migration

```bash
# 1. Navigate to Terraform directory
cd infra/aws

# 2. Plan changes (shows what will be destroyed/created)
terraform plan

# 3. Backup current state
terraform state pull > backup-rupaya.tfstate

# 4. Destroy old infrastructure
terraform destroy

# 5. Apply new infrastructure with new names
terraform apply

# 6. Verify new resources
aws ec2 describe-load-balancers --query "LoadBalancers[*].LoadBalancerName" --region us-east-1
aws ecs list-clusters --region us-east-1
aws ecr describe-repositories --region us-east-1
```

### Step 5: GitHub Repository Migration

```bash
# 1. Create new repository on GitHub: neev
# 2. Update remote URL
git remote set-url origin https://github.com/YOUR_ORG/neev.git

# 3. Push to new repository
git push -u origin main

# 4. Add GitHub Secrets for new repo
# Go to: https://github.com/YOUR_ORG/neev/settings/secrets
# Add: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_ACCOUNT_ID

# 5. Verify workflows trigger on push
git log --oneline -1
git push origin main
# Check: https://github.com/YOUR_ORG/neev/actions
```

### Step 6: Update Local References

```bash
# Update shell aliases and configs
echo 'export NEEV_HOME="/Users/rsingh/Documents/Projects/neev"' >> ~/.zshrc

# Update IDE workspace if using VS Code
# File → Open Folder → Select new neev directory

# Update terminal directory
cd /Users/rsingh/Documents/Projects/neev
```

## Complete Migration Checklist

### Pre-Migration
- [ ] Backup current database: `pg_dump rupaya_db > rupaya_backup.sql`
- [ ] Backup Terraform state: `terraform state pull > backup-rupaya.tfstate`
- [ ] Commit all changes: `git status` should show clean working directory
- [ ] Document current deployment: Record ALB DNS, API endpoint, etc.

### Migration Execution
- [ ] Run migration script: `./scripts/migrate-project.sh rupaya neev`
- [ ] Review changes: `git diff` (should be comprehensive)
- [ ] Test local builds: `npm run build:all`
- [ ] Verify file renames: Check iOS/Android package directories
- [ ] Update GitHub Secrets with AWS credentials

### Infrastructure Deployment
- [ ] Plan Terraform changes: `cd infra/aws && terraform plan`
- [ ] Backup current state: `terraform state pull > backup.tfstate`
- [ ] Destroy old infrastructure: `terraform destroy`
- [ ] Create new infrastructure: `terraform apply`
- [ ] Verify AWS resources created with new names

### Post-Migration
- [ ] Test API endpoints: `curl http://<new-alb-dns>/health`
- [ ] Test mobile builds: iOS and Android local builds
- [ ] Verify GitHub Actions: Push to main and watch workflow
- [ ] Update documentation on new GitHub repo
- [ ] Archive old repository (optional)
- [ ] Update team documentation and runbooks

## What Stays the Same

✅ **No changes needed for:**
- Git commit history (preserved)
- Database schema (same structure)
- API endpoints structure (just URL domain changes)
- Business logic and features
- Dependencies and versions
- Development workflow

## Rollback Procedure

If migration fails, rollback is simple:

```bash
# 1. Reset changes
git reset --hard HEAD

# 2. Restore AWS infrastructure
cd infra/aws
terraform state pull < backup-rupaya.tfstate

# 3. Reapply old infrastructure
terraform apply

# 4. Revert git remote
git remote set-url origin https://github.com/YOUR_ORG/rupaya.git
```

## Example: Rupaya → Neev Migration

**Before:**
```
Repository: github.com/YOUR_ORG/rupaya
iOS: com.rupaya package
Android: com.rupaya package
ECR: rupaya-backend
ECS: rupaya-ecs
API: http://rupaya-alb-xxx.elb.amazonaws.com
```

**After:**
```
Repository: github.com/YOUR_ORG/neev
iOS: com.neev package
Android: com.neev package
ECR: neev-backend
ECS: neev-ecs
API: http://neev-alb-xxx.elb.amazonaws.com
```

## Estimated Time

| Task | Duration |
|------|----------|
| Run migration script | 2-5 min |
| Review changes | 5-10 min |
| Test local builds | 10-15 min |
| Terraform destroy/apply | 15-20 min |
| GitHub repo creation | 2-5 min |
| Total | ~45-60 min |

## Support

If migration fails at any step:

1. **File rename issues**: Manually rename iOS/Android package directories
2. **Terraform issues**: See [ECS_DEPLOYMENT_GUIDE.md](ECS_DEPLOYMENT_GUIDE.md#troubleshooting)
3. **Git issues**: Revert with `git reset --hard`
4. **AWS issues**: Check CloudWatch logs, verify credentials

---

**Notes:**
- Script uses `.git` ignore to prevent accidentally modifying version history
- All changes are reversible via git rollback
- Test in a feature branch first if unsure: `git checkout -b migration/rupaya-to-neev`

