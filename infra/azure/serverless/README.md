# Azure Serverless Stack (Functions)

This stack deploys the backend as an Azure Function App (Node.js) with managed PostgreSQL and Redis.

## Deploy
```bash
cd infra/azure/serverless
terraform init
terraform apply -auto-approve
```

## Deploy code
- Zip your Node.js backend and upload via Azure Portal or Azure CLI.
- Set environment variables as shown in the Function App settings.

## Outputs
- `function_app_url`: public base URL
- `postgres_fqdn`: DB host
- `redis_hostname`: Redis host
