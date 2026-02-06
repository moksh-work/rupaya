# AWS EKS Deployment

This stack creates a managed EKS cluster with auto-scaling node groups, plus RDS Postgres and ElastiCache Redis.

## Deploy
```bash
cd infra/aws/eks
terraform init
terraform apply -auto-approve
```

## Configure kubectl
```bash
aws eks update-kubeconfig \
  --name $(terraform output -raw cluster_name) \
  --region us-east-1
```

## Build & Push Image
```bash
REGION=us-east-1
REPO_URL=$(terraform output -raw ecr_repository_url)
aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "$REPO_URL"
cd backend
docker build -t "$REPO_URL:latest" .
docker push "$REPO_URL:latest"
```

## Deploy to cluster using Helm
```bash
helm install rupaya ../../k8s/helm/rupaya \
  --set image.repository=$REPO_URL \
  --set image.tag=latest \
  --set env.DB_HOST=$(terraform output -raw rds_endpoint) \
  --set env.DB_NAME=rupaya \
  --set env.DB_USER=rupaya \
  --set secrets.dbPassword=<db_password> \
  --set env.REDIS_URL=redis://$(terraform output -raw redis_primary_endpoint):6379
```

## Outputs
- `cluster_endpoint`: EKS API endpoint
- `cluster_name`: Cluster name for kubectl
- `ecr_repository_url`: ECR image repo
- `rds_endpoint`, `redis_primary_endpoint`: DB and cache
