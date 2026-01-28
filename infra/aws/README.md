# RUPAYA AWS Infrastructure (Terraform)

This directory provisions a minimal AWS stack for the backend API using sensible defaults:

- VPC with public (ALB) and private (ECS, RDS, Redis) subnets
- Application Load Balancer (HTTP)
- ECS Fargate service for the Node/Express API
- ECR repository for container images
- RDS Postgres (private)
- ElastiCache Redis replication group (private)
- Secrets Manager (DB password) and CloudWatch Logs

## Prerequisites
- AWS credentials configured (`aws configure`) with access to create resources
- Terraform `>= 1.4`
- Docker installed (to build/push images)

## Configure variables
Copy `terraform.tfvars.example` to `terraform.tfvars` and adjust if desired. Defaults:

```
region = "us-east-1"
project_name = "rupaya"
vpc_cidr = "10.0.0.0/16"
az_count = 2
container_port = 3000
desired_count = 1
db_instance_class = "db.t4g.micro"
db_allocated_storage = 20
db_engine_version = "15.5"
db_name = "rupaya"
db_username = "rupaya"
redis_node_type = "cache.t4g.micro"
image_tag = "latest"
frontend_url = "*"
```

## Deploy

```bash
cd infra/aws
terraform init
terraform plan -out tfplan
terraform apply tfplan
```

On success, note the outputs:
- `alb_dns_name` (public API endpoint)
- `ecr_repository_url`
- `rds_endpoint`
- `redis_primary_endpoint`

## Build and push backend image
From `backend/`:

```bash
# Log in to ECR
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION=$(terraform -chdir=infra/aws output -raw region || echo "us-east-1")
REPO_URL=$(terraform -chdir=infra/aws output -raw ecr_repository_url)
aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "$REPO_URL"

# Build and push
docker build -t "$REPO_URL:latest" .
docker push "$REPO_URL:latest"
```

ECS service uses `image_tag = latest` by default. If the task doesn’t start immediately, force a new deployment:

```bash
aws ecs update-service \
  --cluster rupaya-ecs \
  --service rupaya-backend \
  --force-new-deployment
```

## Connect the app
Set your mobile app base URL to the ALB DNS output with `/api/v1/...` routes. Example:

```
https://<alb_dns_name>/api/v1/auth/otp/request
```

(Current listener is HTTP; switch to HTTPS by adding ACM/Route53 if you have a domain.)

## Clean up

```bash
terraform destroy
```
