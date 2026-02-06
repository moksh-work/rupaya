# Rupaya Backend EKS/Kubernetes Deployment

## Prerequisites
- ECR image built and pushed (update deployment.yaml with your ECR image URL)
- RDS, ElastiCache, and other AWS resources provisioned (see Terraform)
- kubectl and AWS CLI configured for your EKS cluster

## Deploy Steps

1. Update `deployment.yaml` with your ECR image URL and environment variables (DB, Redis, etc).
2. Deploy backend:
   ```sh
   kubectl apply -f deployment.yaml
   kubectl apply -f service.yaml
   kubectl apply -f ingress.yaml
   ```
3. Check status:
   ```sh
   kubectl get pods
   kubectl get svc
   kubectl get ingress
   ```

## Notes
- Ingress assumes AWS ALB; adjust annotations for NGINX or other controllers as needed.
- For production, use Kubernetes secrets for sensitive env vars.
