# This is where you put your variables declaration
variable "cluster_name" {
  default = null
}
variable "region" {
  type        = string
  description = "AWS Region"
}
