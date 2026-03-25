provider "aws" {
  region = var.region
}
locals {
  env = "<%= expansion(':ENV') %>"
  base_roles            = [
    {
      rolearn  = "arn:${var.arn_type}:iam::<%= expansion(':ACCOUNT') %>:role/devops"
      username = "devops"
      groups   = ["system:masters"]
    },
    {
      rolearn  = "arn:${var.arn_type}:iam::<%= expansion(':ACCOUNT') %>:role/admin"
      username = "admin"
      groups   = ["system:masters"]
    }
  ]
  non_prod_roles = can(regex("prod", var.cluster_name)) ? [] : [
    {
      rolearn  = "arn:${var.arn_type}:iam::<%= expansion(':ACCOUNT') %>:role/developers"
      username = "developers"
      groups   = ["system:masters"]
    }
  ]
}
module "eks" {
  source = "../../modules/eks"

  cluster_name                    = var.cluster_name
  cluster_version                 = var.cluster_version
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true
  enable_irsa                     = true
  cluster_ip_family               = "ipv4"
  cluster_security_group_name     = "clustersg-${var.cluster_name}"
  node_security_group_name        = "nodesg-${var.cluster_name}"
  create_iam_role                 = true
  iam_role_name                   = "IAMEKS-${var.cluster_name}"
  subnet_ids                      = var.private_subnets
  cluster_addons                  = {
    #    coredns = {
    #      resolve_conflicts = "OVERWRITE"
    #    }
    kube-proxy = {
      addon_version = "v1.32.0-eksbuild.2"
      resolve_conflicts = "OVERWRITE"
    }
    vpc-cni = {
      addon_version     = "v1.19.2-eksbuild.1"
      resolve_conflicts = "OVERWRITE"
    }
    aws-efs-csi-driver = {
      addon_version = "v2.1.4-eksbuild.1"
      resolve_conflicts = "OVERWRITE"
    }

  }

  cluster_encryption_config = [
    {
      provider_key_arn = aws_kms_key.eks.arn
      resources        = ["secrets"]
    }
  ]

  vpc_id = var.vpc_id

  #  cluster_security_group_additional_rules = {
  #    ingress_self_all = {
  #      description = "Node to node all ports/protocols"
  #      protocol    = "-1"
  #      from_port   = 0
  #      to_port     = 0
  #      type        = "ingress"
  #    }
  #    egress_all = {
  #      description      = "Node all egress"
  #      protocol         = "-1"
  #      from_port        = 0
  #      to_port          = 0
  #      type             = "egress"
  #      cidr_blocks      = ["0.0.0.0/0"]
  #    }
  #  }

  # Extend node-to-node security group rules
  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    #    egress_all = {
    #      description      = "Node all egress"
    #      protocol         = "-1"
    #      from_port        = 0
    #      to_port          = 0
    #      type             = "egress"
    #      cidr_blocks      = ["0.0.0.0/0"]
    #    }
  }

  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = merge({
    ami_type                              = var.eks_ami_type
    disk_size                             = 50
    instance_types                        = []
    ami_release_version                   = var.eks_ami
    vpc_security_group_ids                = [aws_security_group.additional.id]
    attach_cluster_primary_security_group = true

    # Disabling and using externally provided security groups
    create_security_group = false
  },
  var.arn_type == "aws-us-gov" ? {ami_id = var.eks_ami} : {}
  )

  eks_managed_node_groups = {
    ngOne = {
      name            = "<%= expansion(':ENV') %>-eks-cylon-mng"
      use_name_prefix = true
      description     = "EKS managed node group launch template"
      min_size        = var.eks_node_min
      max_size        = var.eks_node_max
      desired_size    = var.eks_node_desired
      key_name        = "cylon-eks-<%= expansion(':ENV') %>-key"

      instance_types = [var.eks_instance_type]
      capacity_type  = var.eks_capacity_type
      labels         = {
        Environment = var.cluster_name
      }
      # Disable pod host on this node group
      #      taints = {
      #        dedicated = {
      #          key    = "dedicated"
      #          value  = "gpuGroup"
      #          effect = "NO_SCHEDULE"
      #        }
      #      }
      ebs_optimized         = true
      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs         = {
            volume_size           = 100
            volume_type           = "gp3"
            encrypted             = true
            kms_key_id            = aws_kms_key.ebs.arn
            delete_on_termination = true
          }
        }
      }
      iam_role_tags                = local.tags
      iam_role_additional_policies = concat(
        [
          "arn:${var.arn_type}:iam::<%= expansion(':ACCOUNT') %>:policy/EC2-STS-Asume-Policy",
          var.cylon_velero_policy_arn,
          var.cylon_node_efs_policy_arn
        ],
        var.arn_type == "aws-us-gov" ? [
        "arn:${var.arn_type}:iam::<%= expansion(':ACCOUNT') %>:policy/csdac-base-assume-iam-policy",
        "arn:${var.arn_type}:iam::aws:policy/AmazonS3ReadOnlyAccess",
        var.csdac_cilium_policy
        ] : []
      )
      tags = local.tags
      enable_bootstrap_user_data = var.user_data

      post_bootstrap_user_data = templatefile(
        local.env == "prdfed" ? "./scripts/userdata_prod.sh" : "./scripts/userdata.sh",
        {
          ClusterName = var.cluster_name,
          AnsiblePublicKey = var.ansible_public_key
        }
      )
    }
  }
  manage_aws_auth_configmap = true
  aws_auth_roles = concat(local.base_roles, local.non_prod_roles)
  aws_auth_users = []
  tags = local.tags

}


### SSH Access to EKS nodes
resource "tls_private_key" "eks" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = "cylon-eks-<%= expansion(':ENV') %>-key"
  public_key = tls_private_key.eks.public_key_openssh
}

resource "aws_kms_key" "ebs" {
  description             = "Customer managed key to encrypt EKS managed node group volumes"
  deletion_window_in_days = 7
  policy                  = data.aws_iam_policy_document.ebs.json
  tags                    = local.tags
}

# This policy is required for the KMS key used for EKS root volumes, so the cluster is allowed to enc/dec/attach encrypted EBS volumes
data "aws_iam_policy_document" "ebs" {
  # Copy of default KMS policy that lets you manage it
  statement {
    sid       = "Enable IAM User Permissions"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:${var.arn_type}:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }

  # Required for EKS
  statement {
    sid     = "Allow service-linked role use of the CMK"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = [
        "arn:${var.arn_type}:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling",
        # required for the ASG to manage encrypted volumes for nodes
        module.eks.cluster_iam_role_arn,
        # required for the cluster / persistentvolume-controller to create encrypted PVCs
      ]
    }
  }

  statement {
    sid       = "Allow attachment of persistent resources"
    actions   = ["kms:CreateGrant"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = [
        "arn:${var.arn_type}:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling",
        # required for the ASG to manage encrypted volumes for nodes
        module.eks.cluster_iam_role_arn,
        # required for the cluster / persistentvolume-controller to create encrypted PVCs
      ]
    }

    condition {
      test     = "Bool"
      variable = "kms:GrantIsForAWSResource"
      values   = ["true"]
    }
  }
}

resource "aws_kms_key" "eks" {
  description             = "EKS Secret Encryption Key"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  tags                    = local.tags
}

data "aws_eks_cluster" "eks" {
  name = module.eks.cluster_id
}

data "aws_caller_identity" "current" {}

data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_id
}

locals {
  name   = replace(basename(var.cluster_name), "_", "-")
  region = var.region
  tags   = {
    DataClassification = "Cisco Highly Confidential"
    ApplicationName    = "Cylon"
    ResourceOwner      = "SBG"
    DataTaxonomy       = "CustomerData+AdministrativeData"
    EnvironmentName    = var.cluster_name
    Environment        = "<%= expansion(':ENV') %>"
    Cluster            = var.cluster_name
    Terraform          = "true"
  }
}

resource "aws_security_group" "additional" {
  name_prefix = "${var.cluster_name}-additional"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.arn_type == "aws-us-gov" ? [
    {
      description = "Allow all for 10.10.6.0/24 and 10.10.7.0/24 ports/protocols for FedRamp",
      from_port = 4118,
      to_port = 4122,
      protocol = "tcp",
      cidr_blocks = ["10.10.6.0/24", "10.10.7.0/24"]
    },
    {
      description = "Allow ssh for 10.10.4.0/24 and 10.10.5.0/24 for FedRamp",
      from_port = 22,
      to_port = 22,
      protocol = "tcp",
      cidr_blocks = ["10.10.4.0/24", "10.10.5.0/24"]
    }
    ] : []

    content {
      description = ingress.value.description
      protocol    = ingress.value.protocol
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

  ingress {
    description = "Allow all for 10.221.0.0/16 and 172.16.0.0/12 ports/protocols"
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["10.221.0.0/16", "172.16.0.0/12"]
  }
  #  egress {
  #    description      = "Allow all any egress ports/protocols"
  #    from_port        = 0
  #    to_port          = 0
  #    protocol         = "-1"
  #    cidr_blocks      = ["0.0.0.0/0"]
  #  }
  tags = local.tags
}
