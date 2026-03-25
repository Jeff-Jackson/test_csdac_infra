subnet_id            = "subnet-0f3f8d251ad63c037"
ami_name             = "produae-cylon-copied-ami"
key_name             = "produae-cylon"
instances_count      = 4
datadog_policy_arn   = "arn:aws:iam::300878470238:policy/produae-cylon-datadog"
rds_read_policy_arn  = "arn:aws:iam::300878470238:policy/produae-cylon-db-ro-secrets"
ecr_pull_policy_arn  = "arn:aws:iam::300878470238:policy/produae-cylon-ecr-ro"
sqs_policy_arn       = "arn:aws:iam::300878470238:policy/produae-cylon-sqs-secrets"

extra_disks = [
  { device = "/dev/xvdf", size_gib = 500 },   # existing volumes will be preserved
  { device = "/dev/xvdg", size_gib = 2048 }
]

create_instance_profile = true
