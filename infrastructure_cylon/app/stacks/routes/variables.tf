variable "region" {
  description = "AWS Region"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC (from vpc stack)"
  type        = string
}

variable "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  type        = string
}

variable "vpc_peering_id" {
  description = "ID of the VPC peering connection"
  type        = string
}

variable "enable_ec2_peering" {
  type        = bool
  description = "Enable VPC peering-related routes to existing EC2 VPC (legacy)"
  default     = false
}

variable "ec2_vpc_tag_name" {
  type        = string
  description = "Tag:Name of existing EC2 VPC to peer with for routes stack"
  default     = "default-vpc"
}
