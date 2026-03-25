output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = module.vpc.private_subnets
}

output "vpc_default_security_group_id" {
  description = "Default SG ID of the VPC"
  value       = module.vpc.default_security_group_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "vpc_peering_id" {
  description = "VPC Peering connection ID"
  value       = var.enable_ec2_peering ? aws_vpc_peering_connection.cylon_peering[0].id : null
}

output "security_group_id" {
  description = "ID of the custom security group"
  value       = module.security_group.security_group_id
}

output "db_access_sg_rule_id" {
  description = "Security group rule ID for DB ingress"
  value       = var.enable_ec2_peering ? aws_security_group_rule.cylon_sg[0].id : null
}

output "db_subnet_group" {
  description = "Name of the DB subnet group"
  value       = module.vpc.database_subnet_group_name
}

output "private_subnet_id" {
  description = "First private subnet ID"
  value       = module.vpc.private_subnets[0]
}
