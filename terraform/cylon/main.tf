data "aws_availability_zones" "available" {}
data "aws_caller_identity" "current" {}

locals {
  name           = "${var.env}-cylon"
  region         = var.region
  account_id     = data.aws_caller_identity.current.account_id
  cylon_ami_id   = can(regex("prod", var.env)) ? "ami-0d8cc390b73143433" : "ami-07715c829b50b992f"
  cdo_account_id = can(regex("prod", var.env)) ? "005087805285" : "107042026245"
  cdo_role       = "arn:aws:iam::${local.cdo_account_id}:role/${var.env}-CRAT@ai-ops-bpr-ecs-task-role"
  vpc_cidr       = can(regex("prod", var.env)) ? "10.0.0.0/16" : "10.200.0.0/16"
  subnet_count   = length(data.aws_availability_zones.available.names)
  azs            = slice(data.aws_availability_zones.available.names, 0, local.subnet_count)

  tags = {
    ResourceName = local.name
    Environment  = "cylon-${var.env}"
    Env          = "cylon-${var.env}"
    Terraform    = "true"
  }

}
