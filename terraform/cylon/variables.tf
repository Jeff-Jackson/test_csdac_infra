# This is where you put your variables declaration
variable "region" {
  default     = "us-west-1"
  description = "Region where EKS hosted"
}
variable "env" {
  description = "Environment type, staging/ci/scale/prod"
}

variable "copy_ami" {
  description = "Copi ami image only for first run"
  type        = bool
  default     = false
}

variable "instances_count" {
  description = "Number of EC2 instances to deploy"
  type        = number
  default     = 1
}
