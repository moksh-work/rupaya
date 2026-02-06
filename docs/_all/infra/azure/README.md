# RUPAYA Azure Infrastructure (Terraform)

Provisions a minimal Azure stack for the backend API:

- Resource Group, VNet, Subnet
- Azure Container Apps (external ingress)
- Azure Container Registry (ACR)
- Azure Database for PostgreSQL Flexible Server
- Azure Cache for Redis (Basic)
- Key Vault (DB password) and Log Analytics workspace

## Defaults
- location: `eastus`
- container_port: 3000

## Deploy
```bash
cd infra/azure
terraform init
terraform apply -auto-approve
```

## Build and push image to ACR
```bash
ACR=$(terraform -chdir=infra/azure output -raw acr_login_server)
az acr login --name ${ACR%%.*}
cd backend
docker build -t "$ACR/rupaya-backend:latest" .
docker push "$ACR/rupaya-backend:latest"
```

## Outputs
- `container_app_fqdn`: public base URL
- `postgres_fqdn`: DB host
- `redis_hostname`: Redis host

Notes:
- Container App injects DB password from Key Vault via a user-assigned identity.
- DB and Redis are public for simplicity; tighten networking for production.
