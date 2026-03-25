variable "env" {
  description = "Deployment environment (e.g. dev, prod)"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID to attach resources to"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for the EC2 instance"
  type        = string
}

variable "ami_name" {
  description = "Name of the existing AMI to launch EC2 instance from"
  type        = string
}

variable "instances_count" {
  description = "Number of EC2 instances to launch"
  type        = number
  default     = 1
}

variable "rds_read_policy_arn" {
  description = "ARN of the RDS read secrets policy"
  type        = string
}

variable "create_key" {
  description = "Whether to create a new SSH key pair"
  type        = bool
  default     = false
}

variable "sqs_policy_arn" {
  description = "ARN of the SQS access policy"
  type        = string
}

variable "key_name" {
  description = "The name of the EC2 key pair to use for SSH access"
  type        = string
}

variable "datadog_policy_arn" {
  description = "ARN of the Datadog monitoring policy"
  type        = string
}

variable "ecr_pull_policy_arn" {
  description = "ARN of the ECR read-only pull policy"
  type        = string
}

variable "extra_disks" {
  description = "Extra EBS disks to attach to EACH instance"
  type = list(object({
    device     = string
    size_gib   = number
    type       = optional(string, "gp3")
    iops       = optional(number)
    throughput = optional(number)
    tags       = optional(map(string), {})
  }))
  default = [
    { device = "/dev/xvdf", size_gib = 500 }
  ]
}

# --- Legacy instance management ---
variable "legacy_instance_name" {
  description = "Name tag of the pre-existing legacy EC2 instance (e.g. prod-cylon)"
  type        = string
  default     = null
}

variable "legacy_extra_disk_device" {
  description = "Device name for the extra EBS volume to attach to the legacy instance (e.g. /dev/xvdi)"
  type        = string
  default     = null
}

variable "legacy_extra_disk_size" {
  description = "Size (in GiB) of the extra EBS volume for the legacy instance"
  type        = number
  default     = null
}

variable "legacy_extra_disk_tags" {
  description = "Additional tags for the legacy EBS volume"
  type        = map(string)
  default     = {}
}

variable "create_instance_profile" {
  description = "Whether to create EC2 instance profile instead of reusing existing one"
  type        = bool
  default     = false
}
