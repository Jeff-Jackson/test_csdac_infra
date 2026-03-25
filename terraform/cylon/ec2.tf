resource "aws_security_group" "cylon" {
 name        = local.name
 description = "sg for cylond"
 vpc_id      = data.aws_vpc.ec2-vpc.id

 ingress {
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["173.38.117.0/24", "173.38.220.43/32", "173.38.220.0/24"]
 }

 ingress {
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = ["173.38.117.0/24", "173.38.220.43/32", "173.36.120.0/24"]
 }
 
 egress {
  from_port        = 0
  to_port          = 0
  protocol         = "-1"
  cidr_blocks      = ["0.0.0.0/0"]
 }

}

data "aws_ami" "copied_ami" {
 filter {
  name = "name"
  values = ["cylon-copied-ami"]
 }
 most_recent = true
 owners = ["self"]
}

resource "tls_private_key" "ssh_key" {
 algorithm = "RSA"
 rsa_bits = 4096
}

resource "aws_key_pair" "ssh_key" {
 key_name = local.name
 public_key = tls_private_key.ssh_key.public_key_openssh
}

resource "aws_instance" "cylon" {
  count         = var.instances_count
  ami           = data.aws_ami.copied_ami.id
  instance_type = "m5.xlarge"
  associate_public_ip_address = true
  iam_instance_profile = aws_iam_instance_profile.cylon.name

  key_name = aws_key_pair.ssh_key.key_name

  metadata_options {
    http_tokens    = "required"
    http_endpoint  = "enabled"
  }

  vpc_security_group_ids = [aws_security_group.cylon.id]
  tags = merge(
    local.tags,
    {
      "Name"  = "${local.name}-${count.index}"
    }
  )
}

resource "aws_iam_instance_profile" "cylon" {
  name = "${local.name}-profile"
  role = aws_iam_role.cylon.name
}
