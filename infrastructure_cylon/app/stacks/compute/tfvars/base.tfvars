# This file is currently empty.
# All configuration values are inherited from global base.tfvars or via outputs.
vpc_id               = <%= output('vpc.vpc_id') %>
create_key           = <%= var.create_key ? "true" : "false" %>
ami_name             = "cylon-copied-ami"
instances_count      = 3
rds_read_policy_arn  = <%= output('database.db_read_secrets_policy_arn') %>
sqs_policy_arn       = <%= output('messaging.sqs_policy_arn') %>
subnet_id            = <%= output('vpc.private_subnet_id') %>

extra_disks = [
  { device = "/dev/xvdf", size_gib = 500 },   # existing volumes will be preserved
  { device = "/dev/xvdg", size_gib = 1024 }   # new volumes 1 TiB
]
