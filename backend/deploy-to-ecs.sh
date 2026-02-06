#!/bin/bash

#############################################################################
# Complete ECS Deployment Script
# Builds, pushes image, and deploys to ECS
# Usage: ./deploy-to-ecs.sh [version] [cluster] [service]
#############################################################################

set -e

# Configuration
VERSION="${1:-latest}"
CLUSTER="${2:-rupaya-ecs}"
SERVICE="${3:-rupaya-backend}"
REGION="us-east-1"
ACCOUNT_ID="843976229340"
ECR_REPO="rupaya-backend"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║         ECS Deployment Pipeline${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Step 1: Build and Push Image
echo -e "${YELLOW}Step 1: Building and Pushing Docker Image${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

REPO_URL="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$ECR_REPO"

if ! "$SCRIPT_DIR/build-and-push.sh" "$VERSION" "$REPO_URL"; then
    echo -e "${RED}✗ Failed to build and push image${NC}"
    exit 1
fi
echo ""

# Step 2: Get current task definition
echo -e "${YELLOW}Step 2: Retrieving Current Task Definition${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

TASK_DEF=$(aws ecs describe-services \
    --cluster "$CLUSTER" \
    --services "$SERVICE" \
    --region "$REGION" \
    --query 'services[0].taskDefinition' \
    --output text)

echo -e "${GREEN}✓ Current task definition: $(echo $TASK_DEF | awk -F: '{print $NF}')${NC}"
echo ""

# Step 3: Register new task definition
echo -e "${YELLOW}Step 3: Registering New Task Definition${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Get the task definition JSON
TASK_DEF_JSON=$(aws ecs describe-task-definition \
    --task-definition "$TASK_DEF" \
    --region "$REGION" \
    --query 'taskDefinition' \
    --output json)

# Update the image
NEW_TASK_DEF=$(echo "$TASK_DEF_JSON" | jq \
    --arg IMAGE "$REPO_URL:$VERSION" \
    '.containerDefinitions[0].image = $IMAGE | 
    del(.taskDefinitionArn, .revision, .status, .requiresAttributes, .compatibilities, .registeredAt, .registeredBy)')

# Register the new task definition
NEW_TASK_DEF_ARN=$(echo "$NEW_TASK_DEF" | aws ecs register-task-definition \
    --region "$REGION" \
    --cli-input-json file:///dev/stdin \
    --query 'taskDefinition.taskDefinitionArn' \
    --output text)

echo -e "${GREEN}✓ New task definition registered: $(echo $NEW_TASK_DEF_ARN | awk -F: '{print $NF}')${NC}"
echo ""

# Step 4: Update ECS service
echo -e "${YELLOW}Step 4: Updating ECS Service${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

UPDATE_RESULT=$(aws ecs update-service \
    --cluster "$CLUSTER" \
    --service "$SERVICE" \
    --task-definition "$NEW_TASK_DEF_ARN" \
    --region "$REGION" \
    --query 'service | {serviceName, status, taskDefinition, runningCount, desiredCount}' \
    --output json)

echo -e "${GREEN}✓ Service updated${NC}"
echo "$UPDATE_RESULT" | jq '.'
echo ""

# Step 5: Wait for deployment
echo -e "${YELLOW}Step 5: Waiting for Deployment${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Waiting for new tasks to start (timeout: 5 minutes)..."

TIMEOUT=300
ELAPSED=0
INTERVAL=10

while [ $ELAPSED -lt $TIMEOUT ]; do
    SERVICE_INFO=$(aws ecs describe-services \
        --cluster "$CLUSTER" \
        --services "$SERVICE" \
        --region "$REGION" \
        --query 'services[0] | {desiredCount, runningCount, pendingCount, deployments: deployments[0] | {status, runningCount}}' \
        --output json)
    
    RUNNING=$(echo "$SERVICE_INFO" | jq -r '.runningCount')
    PENDING=$(echo "$SERVICE_INFO" | jq -r '.pendingCount')
    DESIRED=$(echo "$SERVICE_INFO" | jq -r '.desiredCount')
    DEPLOY_STATUS=$(echo "$SERVICE_INFO" | jq -r '.deployments.status')
    
    echo -ne "  Running: $RUNNING  Pending: $PENDING  Desired: $DESIRED  Status: $DEPLOY_STATUS  \r"
    
    if [ "$RUNNING" -eq "$DESIRED" ] && [ "$PENDING" -eq 0 ]; then
        echo -e "\n${GREEN}✓ Deployment successful!${NC}"
        break
    fi
    
    sleep $INTERVAL
    ELAPSED=$((ELAPSED + INTERVAL))
done

if [ $ELAPSED -ge $TIMEOUT ]; then
    echo -e "\n${YELLOW}⚠ Deployment timeout (5 minutes). Check service status manually.${NC}"
fi
echo ""

# Step 6: Verify deployment
echo -e "${YELLOW}Step 6: Verifying Deployment${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Get running task
TASK_ARN=$(aws ecs list-tasks \
    --cluster "$CLUSTER" \
    --service-name "$SERVICE" \
    --desired-status RUNNING \
    --region "$REGION" \
    --query 'taskArns[0]' \
    --output text)

if [ -z "$TASK_ARN" ] || [ "$TASK_ARN" == "None" ]; then
    echo -e "${RED}✗ No running tasks found${NC}"
    exit 1
fi

# Get task details
TASK_INFO=$(aws ecs describe-tasks \
    --cluster "$CLUSTER" \
    --tasks "$TASK_ARN" \
    --region "$REGION" \
    --query 'tasks[0] | {lastStatus, healthStatus, image: containerInstanceArn, startedAt: .containers[0].startedAt}' \
    --output json)

echo "$TASK_INFO" | jq '.'
echo ""

# Step 7: Health check
echo -e "${YELLOW}Step 7: Running Health Check${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Get ALB DNS
ALB_DNS=$(aws elbv2 describe-load-balancers \
    --query "LoadBalancers[?LoadBalancerName=='rupaya-alb'].DNSName" \
    --output text \
    --region "$REGION")

if [ -z "$ALB_DNS" ]; then
    echo -e "${YELLOW}⚠ ALB DNS not found${NC}"
else
    echo "Testing endpoint: http://$ALB_DNS/health"
    
    for i in {1..5}; do
        if HEALTH=$(curl -s -m 5 "http://$ALB_DNS/health" 2>/dev/null); then
            if echo "$HEALTH" | jq -e '.status == "OK"' &>/dev/null; then
                echo -e "${GREEN}✓ Health check passed: $HEALTH${NC}"
                break
            fi
        fi
        
        if [ $i -lt 5 ]; then
            echo "  Attempt $i/5 - waiting for service to be ready..."
            sleep 3
        fi
    done
fi
echo ""

# Summary
echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║              DEPLOYMENT COMPLETE${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Summary:"
echo "  Cluster: $CLUSTER"
echo "  Service: $SERVICE"
echo "  Image Version: $VERSION"
echo "  Task Definition: $(echo $NEW_TASK_DEF_ARN | awk -F: '{print $NF}')"
echo "  Status: Ready for traffic"
echo ""
echo "Useful commands:"
echo "  View logs:    aws logs tail /ecs/rupaya-backend --follow"
echo "  Describe service: aws ecs describe-services --cluster $CLUSTER --services $SERVICE"
echo "  View tasks:   aws ecs list-tasks --cluster $CLUSTER --service-name $SERVICE"
echo ""
