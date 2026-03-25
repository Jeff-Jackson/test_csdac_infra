variable "vpc_id" {
  description = "VPC ID"
  default     = null
}
variable "region" {
  type        = string
  description = "AWS Region"
}
variable "cluster_name" {
  default     = null
  type        = string
  description = "EKS Cluster name"
}
variable "cluster_version" {
  default     = null
  type        = string
  description = "EKS engine version"
}
variable "eks_instance_type" {
  default     = "m5.xlarge"
  type        = string
  description = "EKS node type"
}
variable "eks_ami_type" {
  default     = "AL2_x86_64"
  type        = string
  description = "EKS ami type"
}
variable "eks_capacity_type" {
  default     = "ON_DEMAND"
  type        = string
  description = "Type of capacity associated with the EKS Node Group. ON_DEMAND/SPOT"
}
variable "eks_node_desired" {
  default     = 3
  type        = number
  description = "EKS EC2 node desired instances count"
}
variable "eks_node_max" {
  default     = 3
  type        = number
  description = "EKS EC2 node max instance count"
}
variable "eks_node_min" {
  default     = 3
  type        = number
  description = "EKS EC2 node min instance count"
}
variable "cylon_velero_policy_arn" {
  type = string
}
variable "private_subnets" {
  type = list(string)
}
variable "eks_ami" {
  type        = string
  description = "Amazon AMI for EKS"
}
variable "user_data" {
  default     = false
  type        = bool
  description = "Enable user data for fips"
}
variable "csdac_cilium_policy" {
  type = string
}
variable "arn_type" {
  default = "aws"
  description = "aws or aws-us-gov"
}
variable "ansible_public_key" {
  default = ""
  description = "Public key for fedramp ansible user"
}
variable "cylon_node_efs_policy_arn" {
  type = string
}
