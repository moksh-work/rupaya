# RUPAYA Helm Chart

Deploy the backend API to any Kubernetes cluster.

## Prerequisites
- A cluster (kind/minikube/EKS/GKE/AKS)
- `kubectl` and `helm` installed
- A container image available to the cluster (e.g., pushed to a registry)

## Install
```bash
# Set the namespace and image repo (example for local kind)
helm install rupaya infra/k8s/helm/rupaya \
  --set image.repository=<your-registry>/rupaya-backend \
  --set image.tag=latest \
  --set env.DB_HOST=<db-host> \
  --set env.DB_NAME=rupaya \
  --set env.DB_USER=rupaya \
  --set secrets.dbPassword=<db-password> \
  --set env.REDIS_URL=redis://<redis-host>:6379
```

Optionally enable ingress:
```bash
helm upgrade rupaya infra/k8s/helm/rupaya \
  --set ingress.enabled=true \
  --set ingress.className=nginx \
  --set ingress.hosts[0].host=api.local \
  --set ingress.hosts[0].paths[0].path=/ \
  --set ingress.hosts[0].paths[0].pathType=Prefix
```

## Notes
- The chart expects env vars compatible with the app (PORT, NODE_ENV, DB_*, REDIS_URL, FRONTEND_URL).
- For production, consider external managed Postgres/Redis and set the corresponding hosts/credentials.
