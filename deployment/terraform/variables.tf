// EKS variables
variable "eks_cluster_name" { type = string }
variable "eks_role_arn" { type = string }
variable "eks_node_role_arn" { type = string }
variable "eks_subnet_ids" { type = list(string) }

// EC2 variables
variable "ec2_ami" { type = string }
variable "ec2_instance_type" { type = string }
variable "ec2_subnet_id" { type = string }
variable "ec2_security_group_ids" { type = list(string) }
variable "ec2_vpc_id" { type = string }
// Terraform variables