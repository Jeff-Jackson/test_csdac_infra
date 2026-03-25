locals {
  tags = {
    DataClassification = "Cisco Highly Confidential"
    ApplicationName = "CSDAC"
    ResourceOwner = "SBG"
    CiscoMailAlias = "dbudko@cisco.com"
    DataTaxonomy = "CustomerData+AdministrativeData"
    EnvironmentName = var.cluster_name
    Environment = "<%= expansion(':ENV') %>"
    Terraform = "true"
  }
}

module "vpc" {
  source = "../../modules/vpc" # updated by terraspace
  
  name                 = "${var.cluster_name}-vpc"
  cidr                 = "10.220.0.0/16"
  azs                  = data.aws_availability_zones.available.names
  private_subnets      = ["10.220.0.0/20", "10.220.16.0/20", "10.220.32.0/20"]
  public_subnets       = ["10.220.128.0/24", "10.220.129.0/24", "10.220.130.0/24"]
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
  map_public_ip_on_launch = true
  enable_flow_log                      = true
  create_flow_log_cloudwatch_iam_role  = true
  create_flow_log_cloudwatch_log_group = true
  manage_default_security_group        = false
  manage_default_route_table           = false 
  manage_default_network_acl           = false
  public_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = "1"
  }
  private_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"           = "1"
  }
  tags = local.tags
}

data "aws_availability_zones" "available" {
}
