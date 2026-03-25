terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.54.1"
    }
  }
}
provider "aws" {
  region = var.region
}

locals {
  instance_keys = toset([for i in range(var.instances_count) : tostring(i)])
}

locals {
  name = "${var.env}-cylon"
  tags = {
    ResourceName = local.name
    Environment  = "cylon-${var.env}"
    Env          = "cylon-${var.env}"
    Terraform    = "true"
    map-migrated = "migAPKOFY9BS4"
  }
}

data "aws_vpc" "ec2_vpc" {
  filter {
    name   = "tag:Name"
    values = ["default-vpc"]
  }
}

data "aws_ami" "copied_ami" {
  filter {
    name   = "name"
    values = [var.ami_name]
  }

  most_recent = true
  owners      = ["self"]
}

locals {
  attachments = {
    for pair in flatten([
      for k in local.instance_keys : [
        for d in var.extra_disks : {
          key          = "${k}-${d.device}"
          instance_key = k
          device       = d.device
          size_gib     = d.size_gib
          type         = try(d.type, "gp3")
          iops         = try(d.iops, null)
          throughput   = try(d.throughput, null)
          tags         = try(d.tags, {})
        }
      ]
    ]) : pair.key => pair
  }
}

resource "tls_private_key" "ssh" {
  count     = var.create_key ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "cylon" {
  count      = var.create_key ? 1 : 0
  key_name   = var.key_name
  public_key = tls_private_key.ssh[0].public_key_openssh
}

resource "local_file" "ssh_private_key" {
  count           = var.create_key ? 1 : 0
  content         = tls_private_key.ssh[0].private_key_pem
  filename        = "${var.env}_id_rsa.pem"
  file_permission = "0400"
}

resource "aws_instance" "cylon" {
  for_each                    = local.instance_keys
  ami                         = data.aws_ami.copied_ami.id
  instance_type               = "m5.xlarge"
  associate_public_ip_address = true
  # iam_instance_profile        = data.aws_iam_instance_profile.cylon.name
  iam_instance_profile        = local.iam_instance_profile_name
  key_name                    = var.create_key ? aws_key_pair.cylon[0].key_name : var.key_name
  subnet_id                   = var.subnet_id

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  # vpc_security_group_ids = [data.aws_security_group.cylon.id]
  vpc_security_group_ids = [aws_security_group.cylon.id]

  tags = merge(
    local.tags,
    {
      Name = "${local.name}-${each.key}"
    }
  )
}

data "aws_instances" "legacy" {
  count = var.legacy_instance_name == null ? 0 : 1

  filter {
    name   = "tag:Name"
    values = [var.legacy_instance_name]
  }
}

data "aws_instance" "legacy" {
  count       = var.legacy_instance_name == null ? 0 : 1
  instance_id = data.aws_instances.legacy[0].ids[0]
}

resource "aws_instance" "cylon_legacy" {
  count = var.legacy_instance_name == null ? 0 : 1

  ami                         = data.aws_instance.legacy[0].ami
  instance_type               = data.aws_instance.legacy[0].instance_type
  subnet_id                   = data.aws_instance.legacy[0].subnet_id
  key_name                    = try(data.aws_instance.legacy[0].key_name, null)
  iam_instance_profile        = try(data.aws_instance.legacy[0].iam_instance_profile, null)
  vpc_security_group_ids      = data.aws_instance.legacy[0].vpc_security_group_ids
  associate_public_ip_address = try(length(data.aws_instance.legacy[0].public_ip) > 0, false)

  tags = merge(
    local.tags,
    { Name = var.legacy_instance_name }
  )

  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      ami,
      instance_type,
      subnet_id,
      key_name,
      iam_instance_profile,
      vpc_security_group_ids,
      associate_public_ip_address,
      user_data,
      metadata_options,
      root_block_device,
      ebs_block_device,
      tags,
    ]
  }
}

resource "aws_security_group" "cylon" {
  name        = local.name
  description = "SG for Cylon EC2"
  vpc_id      = data.aws_vpc.ec2_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["173.38.117.0/24", "173.38.220.43/32", "173.38.220.0/24", "151.186.192.0/20"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["173.38.117.0/24", "173.38.220.43/32", "173.36.120.0/24"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}

# data "aws_security_group" "cylon" {
#   name   = local.name
#   vpc_id = data.aws_vpc.ec2_vpc.id
# }

resource "aws_ebs_volume" "extra" {
  for_each          = local.attachments
  availability_zone = aws_instance.cylon[each.value.instance_key].availability_zone
  size              = each.value.size_gib
  type              = each.value.type
  iops              = each.value.iops
  throughput        = each.value.throughput
  tags = merge(
    {
      Name = "${local.name}-extra-${each.value.instance_key}-${trimprefix(each.value.device, "/dev/")}"
      map-migrated = "migAPKOFY9BS4"
    },
    each.value.tags
  )
}

resource "aws_volume_attachment" "extra" {
  for_each    = local.attachments
  device_name = each.value.device
  volume_id   = aws_ebs_volume.extra[each.key].id
  instance_id = aws_instance.cylon[each.value.instance_key].id
  force_detach = false
}

resource "aws_ebs_volume" "legacy" {
  count             = var.legacy_instance_name == null ? 0 : 1
  availability_zone = aws_instance.cylon_legacy[0].availability_zone
  size              = var.legacy_extra_disk_size
  type              = "gp3"
  tags = merge(
    {
      Name = "${local.name}-legacy-extra"
      map-migrated = "migAPKOFY9BS4"
    },
    var.legacy_extra_disk_tags
  )
}

resource "aws_volume_attachment" "legacy" {
  count       = var.legacy_instance_name == null ? 0 : 1
  device_name = var.legacy_extra_disk_device
  volume_id   = aws_ebs_volume.legacy[0].id
  instance_id = aws_instance.cylon_legacy[0].id
  force_detach = false
}

# --- State migration helpers (from count-based to for_each) ---
# Instances (count -> for_each)
moved {
  from = aws_instance.cylon[0]
  to = aws_instance.cylon["0"]
}

moved {
  from = aws_instance.cylon[1]
  to = aws_instance.cylon["1"]
}

moved {
  from = aws_instance.cylon[2]
  to = aws_instance.cylon["2"]
}

# Volumes (extra_disk[count] -> extra["index-/dev/xvdf"])
moved {
  from = aws_ebs_volume.extra_disk[0]
  to = aws_ebs_volume.extra["0-/dev/xvdf"]
}

moved {
  from = aws_ebs_volume.extra_disk[1]
  to = aws_ebs_volume.extra["1-/dev/xvdf"]
}

moved {
  from = aws_ebs_volume.extra_disk[2]
  to = aws_ebs_volume.extra["2-/dev/xvdf"]
}

# Attachments (attach_disk[count] -> extra["index-/dev/xvdf"])
moved {
  from = aws_volume_attachment.attach_disk[0]
  to = aws_volume_attachment.extra["0-/dev/xvdf"]
}

moved {
  from = aws_volume_attachment.attach_disk[1]
  to = aws_volume_attachment.extra["1-/dev/xvdf"]
}

moved {
  from = aws_volume_attachment.attach_disk[2]
  to = aws_volume_attachment.extra["2-/dev/xvdf"]
}
