# AWS IAM OIDC Provider & Role for GitHub Actions
#
# Enables GitHub Actions to authenticate to AWS without storing credentials.
# Creates:
# 1. OIDC Provider (github.com)
# 2. IAM Role with trust policy
# 3. Inline policy for ECR, ECS, S3, RDS, Secrets Manager access
#
# Usage:
#   terraform apply -target=aws_iam_openid_connect_provider.github \
#                   -target=aws_iam_role.github_oidc \
#                   -target=aws_iam_role_policy.github_oidc_inline
#
# Output:
#   Role ARN → Copy to GitHub secret AWS_OIDC_ROLE_ARN

terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

# ============================================================================
# Variables
# ============================================================================

variable "github_org" {
  description = "GitHub organization name (e.g., 'mycompany')"
  type        = string
  validation {
    condition     = length(var.github_org) > 0
    error_message = "github_org must not be empty"
  }
}

variable "github_repo" {
  description = "GitHub repository name (e.g., 'rupaya')"
  type        = string
  default     = "rupaya"
}

variable "environments" {
  description = "Environments to create OIDC roles for"
  type = map(object({
    role_name            = string
    allowed_branches     = list(string)
    github_environment   = string
  }))
  default = {
    development = {
      role_name            = "rupaya-github-oidc-dev"
      allowed_branches     = ["develop", "feature/*"]
      github_environment   = "development"
    }
    staging = {
      role_name            = "rupaya-github-oidc-staging"
      allowed_branches     = ["release/*"]
      github_environment   = "staging"
    }
    production = {
      role_name            = "rupaya-github-oidc-prod"
      allowed_branches     = ["main"]
      github_environment   = "production"
    }
  }
}

# ============================================================================
# Data Sources
# ============================================================================

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com/.well-known/openid-configuration"
}

# ============================================================================
# GitHub OIDC Provider
# ============================================================================

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github.certificates[0].sha1_fingerprint]

  tags = {
    Name        = "github-oidc-provider"
    Component   = "ci-cd"
    ManagedBy   = "terraform"
  }
}

# ============================================================================
# Trust Policy (Assume Role) - Per Environment
# ============================================================================

data "aws_iam_policy_document" "github_assume_role" {
  for_each = var.environments

  statement {
    sid     = "AllowGitHubOIDCRupaya${title(each.key)}"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = concat(
        [for branch in each.value.allowed_branches : "repo:${var.github_org}/${var.github_repo}:ref:refs/heads/${branch}"],
        ["repo:${var.github_org}/${var.github_repo}:environment:${each.value.github_environment}"]
      )
    }
  }
}

# ============================================================================
# IAM Roles - Per Environment
# ============================================================================

resource "aws_iam_role" "github_oidc" {
  for_each = var.environments

  name               = each.value.role_name
  assume_role_policy = data.aws_iam_policy_document.github_assume_role[each.key].json

  tags = {
    Name        = each.value.role_name
    Environment = each.key
    Component   = "ci-cd"
    ManagedBy   = "terraform"
  }
}

# ============================================================================
# Inline Policy: ECR Access
# ============================================================================

data "aws_iam_policy_document" "ecr_policy" {
  statement {
    sid    = "ECRGetAuthToken"
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "ECRPushImage"
    effect = "Allow"
    actions = [
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer"
    ]
    resources = [
      "arn:aws:ecr:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:repository/rupaya*"
    ]
  }
}

# ============================================================================
# Inline Policy: ECS Access - Per Environment
# ============================================================================

data "aws_iam_policy_document" "ecs_policy" {
  for_each = var.environments

  statement {
    sid    = "ECSUpdateService"
    effect = "Allow"
    actions = [
      "ecs:UpdateService",
      "ecs:DescribeServices",
      "ecs:DescribeTaskDefinition",
      "ecs:RegisterTaskDefinition",
      "ecs:ListTaskDefinitions"
    ]
    resources = [
      "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:service/rupaya-${each.key}/*",
      "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:task-definition/rupaya-*-${each.key}*"
    ]
  }

  statement {
    sid    = "IAMPassRole"
    effect = "Allow"
    actions = [
      "iam:PassRole"
    ]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ecsTaskExecutionRole",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ecsTaskRole"
    ]
  }
}

# ============================================================================
# Inline Policy: Terraform State (S3 + DynamoDB)
# ============================================================================

data "aws_iam_policy_document" "terraform_state_policy" {
  statement {
    sid    = "TerraformStateS3"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = [
      "arn:aws:s3:::rupaya-terraform-state",
      "arn:aws:s3:::rupaya-terraform-state/*"
    ]
  }

  statement {
    sid    = "TerraformStateLock"
    effect = "Allow"
    actions = [
      "dynamodb:DescribeTable",
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem"
    ]
    resources = [
      "arn:aws:dynamodb:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/rupaya-terraform-lock"
    ]
  }
}

# ============================================================================
# Inline Policy: Terraform Infrastructure (EC2, RDS, ACM, CloudFormation, etc)
# ============================================================================

data "aws_iam_policy_document" "terraform_infra_policy" {
  statement {
    sid    = "TerraformInfra"
    effect = "Allow"
    actions = [
      "ec2:*",
      "rds:*",
      "elasticache:*",
      "acm:*",
      "cloudformation:*",
      "logs:*",
      "autoscaling:*",
      "elasticloadbalancing:*",
      "iam:GetRole",
      "iam:ListRoles"
    ]
    resources = ["*"]
  }
}

# ============================================================================
# Inline Policy: RDS Migrations
# ============================================================================

data "aws_iam_policy_document" "rds_migrations_policy" {
  statement {
    sid    = "RDSDescribe"
    effect = "Allow"
    actions = [
      "rds:DescribeDBInstances",
      "rds:DescribeDBClusters",
      "rds:DescribeDBClusterMembers"
    ]
    resources = [
      "arn:aws:rds:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:db/*",
      "arn:aws:rds:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:cluster/*"
    ]
  }
}

# ============================================================================
# Inline Policy: Secrets Manager
# ============================================================================

data "aws_iam_policy_document" "secrets_policy" {
  statement {
    sid    = "SecretsGetValue"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue"
    ]
    resources = [
      "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:rupaya/*"
    ]
  }
}

# ============================================================================
# Attach Policies to Roles - Per Environment
# ============================================================================

resource "aws_iam_role_policy" "github_oidc_inline" {
  for_each = var.environments

  name = "${each.value.role_name}-policy"
  role = aws_iam_role.github_oidc[each.key].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      jsondecode(data.aws_iam_policy_document.ecr_policy.json).Statement,
      jsondecode(data.aws_iam_policy_document.ecs_policy[each.key].json).Statement,
      jsondecode(data.aws_iam_policy_document.terraform_state_policy.json).Statement,
      jsondecode(data.aws_iam_policy_document.terraform_infra_policy.json).Statement,
      jsondecode(data.aws_iam_policy_document.rds_migrations_policy.json).Statement,
      jsondecode(data.aws_iam_policy_document.secrets_policy.json).Statement
    )
  })
}

# ============================================================================
# Outputs
# ============================================================================

output "github_oidc_provider_arn" {
  description = "ARN of GitHub OIDC Provider"
  value       = aws_iam_openid_connect_provider.github.arn
}

output "github_oidc_role_arns" {
  description = "ARNs of GitHub OIDC roles per environment"
  value = {
    for env, role in aws_iam_role.github_oidc : env => role.arn
  }
}

output "github_oidc_role_arn_development" {
  description = "ARN of development OIDC role - use in AWS_OIDC_ROLE_ARN_DEV secret"
  value       = try(aws_iam_role.github_oidc["development"].arn, null)
}

output "github_oidc_role_arn_staging" {
  description = "ARN of staging OIDC role - use in AWS_OIDC_ROLE_ARN_STAGING secret"
  value       = try(aws_iam_role.github_oidc["staging"].arn, null)
}

output "github_oidc_role_arn_production" {
  description = "ARN of production OIDC role - use in AWS_OIDC_ROLE_ARN_PROD secret"
  value       = try(aws_iam_role.github_oidc["production"].arn, null)
}
