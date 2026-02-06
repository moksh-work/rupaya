#!/bin/bash
set -e

# Destroy main environment resources first
cd ../environments
terraform destroy -auto-approve

# Destroy backend state resources after everything else is gone
cd ../bootstrap
terraform destroy -auto-approve

echo "All infrastructure and backend state resources destroyed."

# Manual cleanup instructions for any leftover resources
cat <<EOM

If any resources remain (ECS cluster, RDS instance, VPC), run the following commands manually:

# Delete ECS cluster
aws ecs delete-cluster --cluster rupaya-sandbox-backend-cluster --region us-east-1

# Delete RDS instance
aws rds delete-db-instance --db-instance-identifier rupaya-sandbox-db --skip-final-snapshot --region us-east-1

# Delete VPC (replace <vpc-id> with actual ID)
aws ec2 delete-vpc --vpc-id <vpc-xxxxxxxxxxxxxxxxx> --region us-east-1

EOM
