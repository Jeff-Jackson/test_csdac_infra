variable "region" {
  default = "us-west-1"
  description = "Region where EKS hosted"
}
variable "env" {
  description = "Environment type, dev/qa/stage/prod"
}
variable "eks_cluster_name" {
  type        = string
  default     = ""
  description = "Optional override for EKS cluster name. If empty, defaults to csdac-<env>-cluster"
}
variable "kubectl_ctx" {
  description = "Kubernetes cluster context"
}
variable "kubectl_CA" {
  description = "AWS EKS CA Certificate"
}
variable "arn" {
  default = "aws"
  description = "aws or aws-us-gov"
}

variable "vault_backup_additional_principals" {
  type        = list(string)
  default     = []
  description = "Additional AWS principal ARNs allowed to read/write Vault backup S3 bucket (e.g., devops role)"
}
