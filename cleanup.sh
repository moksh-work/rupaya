#!/bin/bash
set -e
cd /Users/rsingh/Documents/Projects/rupaya

# Abort any ongoing git operations
GIT_EDITOR=true git rebase --abort 2>/dev/null || true
GIT_EDITOR=true git merge --abort 2>/dev/null || true

# Remove duplicate workflow files
rm -f .github/workflows/06-pr-test-suite.yml
rm -f .github/workflows/07-release-test-suite.yml  
rm -f .github/workflows/08-main-test-suite.yml

# Add all changes
git add -A

# Show status
echo "=== Git Status ==="
git status --short

# Commit if there are changes
if ! git diff --cached --quiet; then
  git commit -m "refactor: fix workflow numbering (remove duplicates)"
  echo "=== Committed changes ==="
fi

# Push to GitHub
echo "=== Pushing to GitHub ==="
git push origin feature/test-1

echo "=== Done! ==="
