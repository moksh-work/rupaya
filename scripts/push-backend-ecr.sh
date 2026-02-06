#!/bin/bash
# Build and push backend Docker image to ECR

AWS_REGION="us-east-1"
AWS_ACCOUNT_ID="445830509717"
REPO_NAME="rupaya-backend"
IMAGE_TAG="latest"
ECR_URI="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$REPO_NAME:$IMAGE_TAG"

# Authenticate Docker to ECR
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# Build the Docker image (adjust path as needed)
docker build -t $REPO_NAME ../../backend

docker tag $REPO_NAME:latest $ECR_URI

docker push $ECR_URI

echo "Image pushed: $ECR_URI"
