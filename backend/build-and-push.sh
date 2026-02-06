#!/bin/bash

#############################################################################
# ECS-Compatible Docker Image Builder
# Ensures images are built for linux/amd64 platform (required for ECS)
# Usage: ./build-and-push.sh [tag] [repository-url]
#############################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
TAG="${1:-latest}"
REPO_URL="${2:-843976229340.dkr.ecr.us-east-1.amazonaws.com/rupaya-backend}"
DOCKERFILE_PATH="${3:-./Dockerfile}"
DOCKER_CONTEXT="${4:-.}"

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}ECS Docker Image Builder${NC}"
echo -e "${YELLOW}========================================${NC}"
echo ""
echo "Configuration:"
echo "  Repository: $REPO_URL"
echo "  Tag: $TAG"
echo "  Dockerfile: $DOCKERFILE_PATH"
echo "  Build Context: $DOCKER_CONTEXT"
echo ""

# Step 1: Verify Docker is available
echo -e "${YELLOW}[1/6]${NC} Checking Docker..."
if ! command -v docker &> /dev/null; then
    echo -e "${RED}ERROR: Docker is not installed${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Docker found: $(docker --version)${NC}"
echo ""

# Step 2: Verify docker buildx is available
echo -e "${YELLOW}[2/6]${NC} Checking docker buildx (for multi-platform builds)..."
if ! docker buildx version &> /dev/null; then
    echo -e "${YELLOW}⚠ docker buildx not found, installing...${NC}"
    # Create a builder if it doesn't exist
    docker buildx create --use --name ecs-builder || docker buildx use ecs-builder
fi
echo -e "${GREEN}✓ docker buildx available${NC}"
echo ""

# Step 3: Verify Dockerfile exists
echo -e "${YELLOW}[3/6]${NC} Verifying Dockerfile..."
if [ ! -f "$DOCKERFILE_PATH" ]; then
    echo -e "${RED}ERROR: Dockerfile not found at $DOCKERFILE_PATH${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Dockerfile found${NC}"
echo ""

# Step 4: Check if logged in to ECR
echo -e "${YELLOW}[4/6]${NC} Checking ECR authentication..."
if ! docker info 2>/dev/null | grep -q "Registry"; then
    echo -e "${YELLOW}⚠ Not logged into ECR. Attempting login...${NC}"
    REGISTRY=$(echo $REPO_URL | cut -d'/' -f1)
    REGION=$(echo $REGISTRY | cut -d'.' -f4)
    if aws ecr get-login-password --region $REGION 2>/dev/null | docker login --username AWS --password-stdin $REGISTRY; then
        echo -e "${GREEN}✓ Successfully logged into ECR${NC}"
    else
        echo -e "${RED}ERROR: Failed to login to ECR${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✓ ECR authentication verified${NC}"
fi
echo ""

# Step 5: Build image for linux/amd64 platform
echo -e "${YELLOW}[5/6]${NC} Building Docker image for linux/amd64..."
echo "Command: docker buildx build --platform linux/amd64"
echo "         -t $REPO_URL:$TAG"
echo "         -t $REPO_URL:latest"
echo "         --push"
echo "         -f $DOCKERFILE_PATH"
echo "         $DOCKER_CONTEXT"
echo ""

if docker buildx build \
    --platform linux/amd64 \
    -t "$REPO_URL:$TAG" \
    -t "$REPO_URL:latest" \
    --push \
    -f "$DOCKERFILE_PATH" \
    "$DOCKER_CONTEXT"; then
    echo -e "${GREEN}✓ Image built and pushed successfully${NC}"
else
    echo -e "${RED}ERROR: Failed to build and push image${NC}"
    exit 1
fi
echo ""

# Step 6: Verify image in ECR
echo -e "${YELLOW}[6/6]${NC} Verifying image in ECR..."
REGISTRY=$(echo $REPO_URL | cut -d'/' -f1)
REPO_NAME=$(echo $REPO_URL | cut -d'/' -f2)
REGION=$(echo $REGISTRY | cut -d'.' -f4)

if aws ecr describe-images \
    --registry-id 843976229340 \
    --repository-name "$REPO_NAME" \
    --image-ids imageTag="$TAG" \
    --region "$REGION" &>/dev/null; then
    
    IMAGE_INFO=$(aws ecr describe-images \
        --registry-id 843976229340 \
        --repository-name "$REPO_NAME" \
        --image-ids imageTag="$TAG" \
        --region "$REGION" \
        --query 'imageDetails[0]')
    
    echo -e "${GREEN}✓ Image verified in ECR${NC}"
    echo "  Repository: $REPO_NAME"
    echo "  Tag: $TAG"
    echo "  Pushed at: $(echo $IMAGE_INFO | jq -r '.imagePushedAt')"
    echo "  Size: $(echo $IMAGE_INFO | jq -r '.imageSizeInBytes | . / 1024 / 1024 | round') MB"
else
    echo -e "${RED}ERROR: Failed to verify image in ECR${NC}"
    exit 1
fi
echo ""

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✓ BUILD SUCCESSFUL${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Image Details:"
echo "  Full URL: $REPO_URL:$TAG"
echo "  Platform: linux/amd64 (ECS compatible)"
echo ""
echo "Next steps:"
echo "  1. Update ECS task definition with new image"
echo "  2. Force redeploy: aws ecs update-service --cluster rupaya-ecs --service rupaya-backend --force-new-deployment"
echo ""
