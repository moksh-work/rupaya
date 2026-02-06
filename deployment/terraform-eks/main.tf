// Main Terraform configuration for Rupaya EKS infrastructure

resource "aws_eks_cluster" "main" {
  name     = var.eks_cluster_name
  role_arn = var.eks_role_arn

  vpc_config {
    subnet_ids = var.eks_subnet_ids
  }
}

resource "aws_eks_node_group" "default" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "default"
  node_role_arn   = var.eks_node_role_arn
  subnet_ids      = var.eks_subnet_ids

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }
}
