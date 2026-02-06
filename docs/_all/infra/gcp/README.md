# RUPAYA GCP Infrastructure (Terraform)

Provisions a minimal GCP stack for the backend API:

- VPC with public/private subnets
- Cloud Run (public) with Serverless VPC connector
- Cloud SQL Postgres (public IP for simplicity)
- MemoryStore Redis (private in VPC)
- Artifact Registry
- Secret Manager (DB password)

## Defaults
- project_id: `rupaya-project`
- region: `us-central1`
- container_port: 3000

## Deploy
```bash
cd infra/gcp
terraform init
terraform apply -auto-approve
```

## Build and push image
```bash
REGION=us-central1
REPO="${REGION}-docker.pkg.dev/rupaya-project/rupaya-backend/rupaya-backend"
# Authenticate
gcloud auth configure-docker ${REGION}-docker.pkg.dev
cd backend
docker build -t "$REPO:latest" .
docker push "$REPO:latest"
```

## Outputs
- `cloud_run_url`: public base URL
- `sql_public_ip`: DB host
- `redis_host`: Redis host

Note: Cloud SQL and Redis in this quickstart are reachable from Cloud Run via a VPC connector (Redis) and public IP (SQL). For production, prefer private IP Cloud SQL + authorized networks tightened.
