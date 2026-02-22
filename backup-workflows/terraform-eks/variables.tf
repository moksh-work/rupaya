// EKS variables
variable "eks_cluster_name" { type = string }
variable "eks_role_arn" { type = string }
variable "eks_node_role_arn" { type = string }
variable "eks_subnet_ids" { type = list(string) }
