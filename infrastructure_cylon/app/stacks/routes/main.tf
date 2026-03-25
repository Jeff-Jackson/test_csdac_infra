provider "aws" {
  region = var.region
}

locals {
  cylon_route_tables_ids = var.enable_ec2_peering ? data.aws_route_tables.cylon_route_tables[0].ids : []
  ec2_route_tables_ids   = var.enable_ec2_peering ? data.aws_route_tables.ec2_route_tables[0].ids : []
}

data "aws_vpc" "ec2_vpc" {
  count = var.enable_ec2_peering ? 1 : 0

  filter {
    name   = "tag:Name"
    values = [var.ec2_vpc_tag_name]
  }
}

data "aws_route_tables" "cylon_route_tables" {
  count  = var.enable_ec2_peering ? 1 : 0
  vpc_id = var.vpc_id
}

data "aws_route_tables" "ec2_route_tables" {
  count  = var.enable_ec2_peering ? 1 : 0
  vpc_id = data.aws_vpc.ec2_vpc[0].id
}

resource "aws_route" "cylon_route" {
  count                     = length(local.cylon_route_tables_ids)
  route_table_id            = local.cylon_route_tables_ids[count.index]
  destination_cidr_block    = data.aws_vpc.ec2_vpc[0].cidr_block
  vpc_peering_connection_id = var.vpc_peering_id
}

resource "aws_route" "ec2_rout" {
  count                     = length(local.ec2_route_tables_ids)
  route_table_id            = local.ec2_route_tables_ids[count.index]
  destination_cidr_block    = var.vpc_cidr_block
  vpc_peering_connection_id = var.vpc_peering_id
}
