locals {
  cylon_route_tables_ids = data.aws_route_tables.cylon-rout-tables.ids
  ec2_route_tables_ids   = data.aws_route_tables.ec2-rout-tables.ids
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = local.name
  cidr = local.vpc_cidr

  azs              = local.azs
  private_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 3)]
  database_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 8)]

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

data "aws_vpc" "ec2-vpc" {
  filter {
    name   = "tag:Name"
    values = ["default-vpc"]
  }
}

data "aws_route_tables" "cylon-rout-tables" {
  vpc_id = module.vpc.vpc_id
  depends_on = [module.vpc]
}

data "aws_route_tables" "ec2-rout-tables" {
  vpc_id = data.aws_vpc.ec2-vpc.id
}

resource "aws_vpc_peering_connection" "cylon-peering" {
  peer_vpc_id = module.vpc.vpc_id
  vpc_id      = data.aws_vpc.ec2-vpc.id
  auto_accept = true

  tags = local.tags
}

resource "aws_route" "cylon-rout" {
  count                     = length(local.cylon_route_tables_ids)
  route_table_id            = local.cylon_route_tables_ids[count.index]
  destination_cidr_block    = data.aws_vpc.ec2-vpc.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.cylon-peering.id
  depends_on = [module.vpc]
}

resource "aws_route" "ec2-rout-tables" {
  count                     = length(local.ec2_route_tables_ids)
  route_table_id            = local.ec2_route_tables_ids[count.index]
  destination_cidr_block    = module.vpc.vpc_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.cylon-peering.id
}

resource "aws_security_group_rule" "cylon_sg" {
  type              = "ingress"
  from_port         = module.db.db_instance_port
  to_port           = module.db.db_instance_port
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.ec2-vpc.cidr_block]
  security_group_id = module.security_group.security_group_id
}
