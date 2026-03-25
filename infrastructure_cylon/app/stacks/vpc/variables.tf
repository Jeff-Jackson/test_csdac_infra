# This is where you put your variables declaration
variable "cluster_name" {
  default = null
  type    = string
}

variable "region" {
  type        = string
  description = "AWS Region"
}

variable "env" {
  description = "Environment type, staging/ci/scale/prod"
  type        = string
}

variable "enable_ec2_peering" {
  type        = bool
  description = "Enable VPC peering and SG rule to existing EC2 VPC (legacy)"
  default     = false
}

variable "ec2_vpc_tag_name" {
  type        = string
  description = "Tag:Name of existing EC2 VPC to peer with"
  default     = "default-vpc"
}

variable "db_port" {
  type        = number
  description = "Database port for SG rule from EC2 VPC"
  default     = 3306
}
