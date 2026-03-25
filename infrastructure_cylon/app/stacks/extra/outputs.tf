output "cylon_velero_policy_arn" {
  description = "Additional policy for EKS (EC2 nodes) to have an access from k8s to AWS S3 for Velero"
  value = aws_iam_policy.cylon_velero_policy.arn
}
output "cylon_cilium_policy" {
  description = "Additional policy for EKS (EC2 nodes) for cilium work"
  value = length(aws_iam_policy.cylon_cilium_policy) > 0 ? aws_iam_policy.cylon_cilium_policy[0].arn : null
}
output "cylon_node_efs_policy" {
  description = "Additional policy for EKS (EC2 nodes) to use EFS"
  value = aws_iam_policy.node_efs_policy.arn
}
