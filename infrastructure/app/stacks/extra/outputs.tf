output "csdac_vault_policy_arn" {
  description = "Additional policy for EKS (EC2 nodes) to have an access from k8s to AWS resources for Vault"
  value = aws_iam_policy.csdac_vault_policy.arn
}
output "csdac_velero_policy_arn" {
  description = "Additional policy for EKS (EC2 nodes) to have an access from k8s to AWS S3 for Velero"
  value = aws_iam_policy.csdac_velero_policy.arn
}

output "csdac_cilium_policy" {
  description = "Additional policy for EKS (EC2 nodes) for cilium work"
  value = length(aws_iam_policy.csdac_cilium_policy) > 0 ? aws_iam_policy.csdac_cilium_policy[0].arn : null
}
