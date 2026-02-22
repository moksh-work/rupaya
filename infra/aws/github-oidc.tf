# GitHub Actions OIDC Provider and CI/CD Role

data "aws_caller_identity" "current" {}

data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com"
}

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github.certificates[0].sha1_fingerprint]

  tags = {
    Name = "GitHub Actions OIDC Provider"
  }
}

# CI/CD Role for GitHub Actions
resource "aws_iam_role" "github_actions_cicd" {
  name               = "${var.project_name}-terraform-cicd"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}/${var.github_repo}:ref:refs/heads/main"
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name} GitHub Actions CI/CD Role"
  }
}

# Policy for Terraform state access
resource "aws_iam_role_policy" "github_actions_terraform" {
  name = "${var.project_name}-terraform-state"
  role = aws_iam_role.github_actions_cicd.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "arn:aws:s3:::rupaya-terraform-state-590184132516",
          "arn:aws:s3:::rupaya-terraform-state-590184132516/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:DescribeTable",
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem"
        ]
        Resource = "arn:aws:dynamodb:${var.region}:${data.aws_caller_identity.current.account_id}:table/rupaya-terraform-state-lock"
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = "*"
      }
    ]
  })
}

# Policy for AWS infrastructure management
resource "aws_iam_role_policy" "github_actions_aws" {
  name = "${var.project_name}-aws-infrastructure"
  role = aws_iam_role.github_actions_cicd.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:*",
          "ecs:*",
          "elasticache:*",
          "rds:*",
          "elasticloadbalancing:*",
          "route53:*",
          "acm:*",
          "secretsmanager:GetSecretValue",
          "cloudwatch:*",
          "logs:*"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:*"
        ]
        Resource = "arn:aws:ecr:${var.region}:${data.aws_caller_identity.current.account_id}:repository/${var.project_name}-*"
      },
      {
        Effect = "Allow"
        Action = [
          "iam:GetRole",
          "iam:PassRole"
        ]
        Resource = [
          aws_iam_role.ecs_task_execution.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "iam:*"
        ]
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project_name}*"
      }
    ]
  })
}

# Trust policy to allow additional GitHub branches (modify assume role policy if needed)
# The main assume role policy in aws_iam_role already handles authentication


output "github_actions_role_arn" {
  description = "ARN of the GitHub Actions CI/CD IAM role"
  value       = aws_iam_role.github_actions_cicd.arn
}

output "github_oidc_provider_arn" {
  description = "ARN of the GitHub OIDC provider"
  value       = aws_iam_openid_connect_provider.github.arn
}
