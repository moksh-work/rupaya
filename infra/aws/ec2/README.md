# AWS EC2 Stack (ALB + ASG)

Deploys the backend on EC2 instances running Docker behind an ALB. Includes RDS Postgres and ElastiCache Redis.

## Deploy
```bash
cd infra/aws/ec2
terraform init
terraform apply -auto-approve
```

## Build & Push Image
```bash
REGION=us-east-1
REPO_URL=$(terraform -chdir=infra/aws/ec2 output -raw ecr_repository_url)
aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "$REPO_URL"
cd backend
docker build -t "$REPO_URL:latest" .
docker push "$REPO_URL:latest"
```

## Notes
- User data starts the container using env vars; update `compute.tf` if you need different flags.
- Set app base URL to `alb_dns_name` output.
