// EC2 variables
variable "ec2_ami" { type = string }
variable "ec2_instance_type" { type = string }
variable "ec2_subnet_id" { type = string }
variable "ec2_security_group_ids" { type = list(string) }
variable "ec2_vpc_id" { type = string }
