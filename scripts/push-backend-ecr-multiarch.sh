#!/bin/bash
# Build and push multi-arch backend Docker image to ECR for ECS Fargate

AWS_REGION="us-east-1"
AWS_ACCOUNT_ID="445830509717"
REPO_NAME="rupaya-backend"
IMAGE_TAG="latest"
ECR_URI="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$REPO_NAME:$IMAGE_TAG"

# Authenticate Docker to ECR
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# Enable Docker Buildx (multi-arch builder)
docker buildx create --use || true

docker buildx build --platform linux/amd64,linux/arm64 -t $ECR_URI ../../backend --push

echo "Multi-arch image pushed: $ECR_URI"
