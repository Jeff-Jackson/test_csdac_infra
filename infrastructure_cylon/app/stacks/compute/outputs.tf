output "instance_ids" {
  description = "IDs of the launched EC2 instances"
  value       = [for inst in aws_instance.cylon : inst.id]
}

output "security_group_id" {
  description = "Security Group used by EC2 instances"
  value       = aws_security_group.cylon.id
}

# output "instance_profile_arn" {
#   description = "ARN of the IAM instance profile for EC2"
#   value       = aws_iam_instance_profile.instance_profile.arn
# }

## This is need for NEWLY CREATED policy
output "ecr_pull_policy_arn" {
  description = "ARN of the ECR read-only IAM policy"
  value       = aws_iam_policy.ecr_pull_policy.arn
}

# output "datadog_policy_arn" {
#   description = "ARN of the Datadog IAM policy"
#   value       = aws_iam_policy.datadog_policy.arn
# }

# output "ecr_pull_policy_arn" {
#   description = "ARN of the reused ECR read-only IAM policy"
#   value       = var.ecr_pull_policy_arn
# }

# This is need for EXISTING policy
output "datadog_policy_arn" {
  description = "ARN of the reused Datadog IAM policy"
  value       = var.datadog_policy_arn
}

output "instance_public_ips" {
  description = "Public IP addresses of EC2 instances"
  value       = [for instance in aws_instance.cylon : instance.public_ip]
}

output "instance_public_dns" {
  description = "Public DNS names of EC2 instances"
  value       = [for instance in aws_instance.cylon : instance.public_dns]
}

# output "sg_vpc_id" {
#   value = aws_security_group.cylon.vpc_id
# }
