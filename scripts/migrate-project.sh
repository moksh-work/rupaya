#!/bin/bash

# ====================================================================
# Project Migration Script
# ====================================================================
# Automatically rename a project and update all references
#
# Usage: ./scripts/migrate-project.sh <old_name> <new_name>
# Example: ./scripts/migrate-project.sh rupaya neev
#
# This script will:
# 1. Update all file contents (code, config, docs)
# 2. Rename iOS/Android package directories
# 3. Update Terraform variables
# 4. Update GitHub Actions workflows
# 5. Preserve git history
#
# Safe to run: All changes are git-tracked and reversible
# ====================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ====================================================================
# Validation
# ====================================================================

if [ "$#" -ne 2 ]; then
    echo -e "${RED}Usage: $0 <old_name> <new_name>${NC}"
    echo "Example: $0 rupaya neev"
    echo ""
    echo "This script will migrate the entire project to a new name."
    echo "All changes are git-tracked and can be reverted with: git reset --hard"
    exit 1
fi

OLD_NAME="$1"
NEW_NAME="$2"

# Validation checks
if [ -z "$OLD_NAME" ] || [ -z "$NEW_NAME" ]; then
    echo -e "${RED}❌ Error: Names cannot be empty${NC}"
    exit 1
fi

if [ "$OLD_NAME" = "$NEW_NAME" ]; then
    echo -e "${RED}❌ Error: Old and new names must be different${NC}"
    exit 1
fi

# Check if git is clean
if [ -n "$(git status --porcelain)" ]; then
    echo -e "${YELLOW}⚠️  Warning: Git working directory is not clean${NC}"
    echo "Uncommitted changes detected. Commit or stash before migrating."
    echo ""
    echo "Current status:"
    git status
    echo ""
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Get project root
PROJECT_ROOT=$(git rev-parse --show-toplevel)
cd "$PROJECT_ROOT"

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║           Project Migration: $OLD_NAME → $NEW_NAME           ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Migration Details:${NC}"
echo "  Old Name: $OLD_NAME"
echo "  New Name: $NEW_NAME"
echo "  Location: $PROJECT_ROOT"
echo ""

# ====================================================================
# Phase 1: Update File Contents
# ====================================================================

echo -e "${BLUE}📝 Phase 1: Updating file contents${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Helper function to replace in files
replace_in_files() {
    local pattern="$1"
    local replacement="$2"
    local file_pattern="$3"
    local description="$4"
    
    if find . $file_pattern ! -path "./.git/*" ! -path "./node_modules/*" ! -path "./.venv/*" ! -path "./.terraform/*" ! -path "./.gradle/*" 2>/dev/null | grep -q .; then
        echo -e "  ${GREEN}✓${NC} $description"
        find . $file_pattern ! -path "./.git/*" ! -path "./node_modules/*" ! -path "./.venv/*" ! -path "./.terraform/*" ! -path "./.gradle/*" 2>/dev/null -exec sed -i '' "s/${pattern}/${replacement}/g" {} \;
    fi
}

# 1. Shell scripts
replace_in_files "$OLD_NAME" "$NEW_NAME" "-name '*.sh' -type f" "Shell scripts (.sh)"

# 2. Python scripts
replace_in_files "$OLD_NAME" "$NEW_NAME" "-name '*.py' -type f" "Python files (.py)"

# 3. Swift files (iOS)
replace_in_files "$OLD_NAME" "$NEW_NAME" "-path 'ios/*' -name '*.swift' -type f" "iOS Swift files"

# 4. Kotlin files (Android)
replace_in_files "$OLD_NAME" "$NEW_NAME" "-path 'android/*' -name '*.kt' -type f" "Android Kotlin files"

# 5. JavaScript files (Backend)
replace_in_files "$OLD_NAME" "$NEW_NAME" "-path 'backend/*' -name '*.js' -type f" "Backend JavaScript files"

# 6. JSON files (package.json, etc.)
replace_in_files "$OLD_NAME" "$NEW_NAME" "-name '*.json' -type f" "JSON configuration files"

# 7. Terraform files
replace_in_files "$OLD_NAME" "$NEW_NAME" "-path 'infra/*' -name '*.tf' -type f" "Terraform files (.tf)"

# 8. YAML files (GitHub Actions)
replace_in_files "$OLD_NAME" "$NEW_NAME" "-path '.github/*' -name '*.yml' -o -path '.github/*' -name '*.yaml'" "GitHub Actions workflows"

# 9. Markdown files
replace_in_files "$OLD_NAME" "$NEW_NAME" "-name '*.md' -type f" "Markdown documentation files"

# 10. Gradle files
replace_in_files "$OLD_NAME" "$NEW_NAME" "-path 'android/*' -name '*.gradle*' -type f" "Android Gradle files"

# 11. AndroidManifest.xml
replace_in_files "$OLD_NAME" "$NEW_NAME" "-path 'android/*' -name 'AndroidManifest.xml' -type f" "Android manifest files"

# 12. Podfile
if [ -f "ios/Podfile" ]; then
    sed -i '' "s/$OLD_NAME/$NEW_NAME/g" ios/Podfile
    echo -e "  ${GREEN}✓${NC} iOS Podfile"
fi

# 13. Docker files
replace_in_files "$OLD_NAME" "$NEW_NAME" "-name 'Dockerfile*' -type f" "Docker files"

# 14. Compose files
replace_in_files "$OLD_NAME" "$NEW_NAME" "-name 'docker-compose*' -type f" "Docker Compose files"

echo ""

# ====================================================================
# Phase 2: Rename Directories
# ====================================================================

echo -e "${BLUE}📁 Phase 2: Renaming directories and packages${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# iOS directory rename
OLD_NAME_UC=$(echo "$OLD_NAME" | tr '[:lower:]' '[:upper:]')
NEW_NAME_UC=$(echo "$NEW_NAME" | tr '[:lower:]' '[:upper:]')

if [ -d "ios/$OLD_NAME_UC" ]; then
    mv "ios/$OLD_NAME_UC" "ios/$NEW_NAME_UC"
    echo -e "  ${GREEN}✓${NC} iOS app directory: ios/$OLD_NAME_UC → ios/$NEW_NAME_UC"
fi

# Android package directory rename
if [ -d "android/app/src/main/kotlin/com/$OLD_NAME" ]; then
    mkdir -p "android/app/src/main/kotlin/com/$NEW_NAME"
    cp -r "android/app/src/main/kotlin/com/$OLD_NAME"/* "android/app/src/main/kotlin/com/$NEW_NAME/"
    rm -rf "android/app/src/main/kotlin/com/$OLD_NAME"
    echo -e "  ${GREEN}✓${NC} Android package: com.$OLD_NAME → com.$NEW_NAME"
elif [ -d "android/app/src/main/java/com/$OLD_NAME" ]; then
    mkdir -p "android/app/src/main/java/com/$NEW_NAME"
    cp -r "android/app/src/main/java/com/$OLD_NAME"/* "android/app/src/main/java/com/$NEW_NAME/"
    rm -rf "android/app/src/main/java/com/$OLD_NAME"
    echo -e "  ${GREEN}✓${NC} Android package: com.$OLD_NAME → com.$NEW_NAME"
fi

echo ""

# ====================================================================
# Phase 3: Special Configuration Updates
# ====================================================================

echo -e "${BLUE}⚙️  Phase 3: Updating configuration files${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Update Terraform tfvars if it exists
if [ -f "infra/aws/terraform.tfvars" ]; then
    sed -i '' "s/project_name = \"$OLD_NAME\"/project_name = \"$NEW_NAME\"/" infra/aws/terraform.tfvars
    echo -e "  ${GREEN}✓${NC} Terraform variables (terraform.tfvars)"
fi

# Update package.json name
if [ -f "package.json" ]; then
    sed -i '' "s/\"name\": \"$OLD_NAME-monorepo\"/\"name\": \"$NEW_NAME-monorepo\"/" package.json
    sed -i '' "s/\"description\": \".*$OLD_NAME.*/\"description\": \"$NEW_NAME Money Manager - Monorepo\",/" package.json
    echo -e "  ${GREEN}✓${NC} Root package.json"
fi

# Update backend package.json
if [ -f "backend/package.json" ]; then
    sed -i '' "s/\"name\": \"$OLD_NAME-backend\"/\"name\": \"$NEW_NAME-backend\"/" backend/package.json
    echo -e "  ${GREEN}✓${NC} Backend package.json"
fi

echo ""

# ====================================================================
# Phase 4: Summary
# ====================================================================

echo -e "${BLUE}✅ Migration Complete!${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${YELLOW}📋 Changes Summary:${NC}"
echo "  • Updated all file contents"
echo "  • Renamed iOS directory: $OLD_NAME_UC → $NEW_NAME_UC"
echo "  • Renamed Android packages: com.$OLD_NAME → com.$NEW_NAME"
echo "  • Updated configuration files"
echo "  • Updated GitHub workflows"
echo ""

# Show git diff summary
CHANGES=$(git diff --name-only | wc -l)
echo -e "${YELLOW}📊 Changed Files:${NC} $CHANGES files modified"
echo ""

# List changed files
echo -e "${YELLOW}Files Changed:${NC}"
git diff --name-only | head -20 | awk '{print "  • " $0}'
if [ "$CHANGES" -gt 20 ]; then
    echo "  ... and $((CHANGES - 20)) more files"
fi

echo ""
echo -e "${YELLOW}📋 Next Steps:${NC}"
echo "  1. Review changes: ${BLUE}git diff${NC}"
echo "  2. Test builds: ${BLUE}npm run build:all${NC}"
echo "  3. Commit changes: ${BLUE}git add . && git commit -m 'Migration: $OLD_NAME → $NEW_NAME'${NC}"
echo "  4. Create new GitHub repository: ${BLUE}$NEW_NAME${NC}"
echo "  5. Update git remote: ${BLUE}git remote set-url origin <new-repo-url>${NC}"
echo "  6. Deploy infrastructure: ${BLUE}cd infra/aws && terraform apply${NC}"
echo ""
echo -e "${YELLOW}⚠️  Rollback:${NC}"
echo "  If needed, revert with: ${BLUE}git reset --hard${NC}"
echo ""

exit 0
