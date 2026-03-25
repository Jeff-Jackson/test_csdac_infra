# locals {
#   key_name           = "${var.env}-cylon"
#   # Use this wherever a key name is required (e.g. EC2 instance)
#   effective_key_name = var.create_key ? aws_key_pair.generated[0].key_name : data.aws_key_pair.existing[0].key_name
# }
locals {
  key_name = var.key_name != "" ? var.key_name : "${var.env}-cylon"
}

# resource "tls_private_key" "ssh_key" {
#   count     = var.create_key ? 1 : 0
#   algorithm = "RSA"
#   rsa_bits  = 4096
# }

# resource "aws_key_pair" "generated" {
#   count      = var.create_key ? 1 : 0
#   key_name   = local.key_name
#   public_key = tls_private_key.ssh_key[0].public_key_openssh
# }

# Data resource to reference existing key when not creating a new one
data "aws_key_pair" "existing" {
  count    = var.create_key ? 0 : 1
  key_name = local.key_name
}

# resource "local_file" "pem_file" {
#   count    = var.create_key ? 1 : 0
#   content  = tls_private_key.ssh_key[0].private_key_pem
#   filename = "${path.module}/${var.env}_id_rsa.pem"
#   file_permission = "0600"
# }
