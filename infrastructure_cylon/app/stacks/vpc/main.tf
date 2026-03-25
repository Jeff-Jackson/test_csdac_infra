provider "aws" {
  region = var.region
}

locals {
  name       = "${var.env}-cylon"
  account_id = data.aws_caller_identity.current.account_id
  tags = {
    DataClassification = "Cisco Highly Confidential"
    ApplicationName    = "CYLON"
    ResourceOwner      = "SBG"
    DataTaxonomy       = "CustomerData+AdministrativeData"
    EnvironmentName    = var.cluster_name
    ResourceName       = local.name
    Environment        = "cylon-${var.env}"
    Terraform          = "true"
  }
  vpc_cidr     = can(regex("prod", var.env)) ? "10.0.0.0/16" : "10.200.0.0/16"
  subnet_count = length(data.aws_availability_zones.available.names)
  azs          = slice(data.aws_availability_zones.available.names, 0, local.subnet_count)
}

data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = local.name
  cidr = local.vpc_cidr

  azs              = local.azs
  private_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 3)]
  database_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 6)]

  create_database_subnet_group = true

  tags = local.tags
}

module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = local.name
  description = "Complete MySQL example security group"
  vpc_id      = module.vpc.vpc_id

  # ingress
  ingress_with_cidr_blocks = [
    {
      from_port   = 3306
      to_port     = 3306
      protocol    = "tcp"
      description = "MySQL access from within VPC"
      cidr_blocks = module.vpc.vpc_cidr_block
    },
  ]

  tags = local.tags
}

# Optional peering to existing EC2 VPC (e.g., legacy default-vpc)
# Controlled by var.enable_ec2_peering to avoid failures in regions
# where that VPC does not exist.
data "aws_vpc" "ec2_vpc" {
  count = var.enable_ec2_peering ? 1 : 0

  filter {
    name   = "tag:Name"
    values = [var.ec2_vpc_tag_name]
  }
}

resource "aws_vpc_peering_connection" "cylon_peering" {
  count       = var.enable_ec2_peering ? 1 : 0
  peer_vpc_id = module.vpc.vpc_id
  vpc_id      = data.aws_vpc.ec2_vpc[0].id
  auto_accept = true

  tags = local.tags
}

resource "aws_security_group_rule" "cylon_sg" {
  count             = var.enable_ec2_peering ? 1 : 0
  type              = "ingress"
  from_port         = var.db_port
  to_port           = var.db_port
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.ec2_vpc[0].cidr_block]
  security_group_id = module.security_group.security_group_id
}

data "aws_route_tables" "cylon_route_tables" {
  vpc_id     = module.vpc.vpc_id
  depends_on = [module.vpc]
}

data "aws_route_tables" "ec2_route_tables" {
  count  = var.enable_ec2_peering ? 1 : 0
  vpc_id = data.aws_vpc.ec2_vpc[0].id
}

locals {
  cylon_route_tables_ids = data.aws_route_tables.cylon_route_tables.ids
  ec2_route_tables_ids   = var.enable_ec2_peering ? data.aws_route_tables.ec2_route_tables[0].ids : []
}

resource "aws_route" "cylon_routes" {
  count                     = var.enable_ec2_peering ? length(local.cylon_route_tables_ids) : 0
  route_table_id            = local.cylon_route_tables_ids[count.index]
  destination_cidr_block    = data.aws_vpc.ec2_vpc[0].cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.cylon_peering[0].id

  depends_on = [aws_vpc_peering_connection.cylon_peering]
}

resource "aws_route" "ec2_routes" {
  count                     = var.enable_ec2_peering ? length(local.ec2_route_tables_ids) : 0
  route_table_id            = local.ec2_route_tables_ids[count.index]
  destination_cidr_block    = module.vpc.vpc_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.cylon_peering[0].id

  depends_on = [aws_vpc_peering_connection.cylon_peering]
}
