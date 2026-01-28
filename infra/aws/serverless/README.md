# AWS Serverless Stack (Lambda + API Gateway)

This stack deploys the backend as a Lambda (container image) behind an HTTP API.
It provisions Aurora PostgreSQL Serverless v2 and ElastiCache Redis.

## Deploy
```bash
cd infra/aws/serverless
terraform init
terraform apply -auto-approve
```

## Build & Push Image
Use the ECR repo created in this stack:
```bash
REGION=us-east-1
REPO_URL=$(terraform output -raw http_api_endpoint >/dev/null 2>&1; aws ecr describe-repositories --region $REGION --query 'repositories[?repositoryName==`rupaya-backend`].repositoryUri' --output text)
aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "$REPO_URL"
cd backend
docker build -t "$REPO_URL:latest" .
docker push "$REPO_URL:latest"
```

Note: Running Express on Lambda typically requires the AWS Lambda Web Adapter or serverless-express. If your image includes the adapter, set `AWS_LAMBDA_EXEC_WRAPPER` accordingly.

## Outputs
- `http_api_endpoint`: public base URL
- `aurora_endpoint`: DB host
- `redis_primary_endpoint`: Redis host
