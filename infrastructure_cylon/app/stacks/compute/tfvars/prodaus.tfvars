subnet_id            = "subnet-01086534344f5110a"
ami_name             = "prodaus-cylon-copied-ami"
key_name             = "prodaus-cylon"
instances_count      = 3
datadog_policy_arn   = "arn:aws:iam::300878470238:policy/prodaus-cylon-datadog"
rds_read_policy_arn  = "arn:aws:iam::300878470238:policy/prodaus-cylon-db-ro-secrets"
ecr_pull_policy_arn  = "arn:aws:iam::300878470238:policy/prodaus-cylon-ecr-ro"
sqs_policy_arn       = "arn:aws:iam::300878470238:policy/prodaus-cylon-sqs-secrets"

extra_disks = [
  { device = "/dev/xvdf", size_gib = 500 },   # existing volumes will be preserved
  { device = "/dev/xvdg", size_gib = 1024 }   # new volumes 1 TiB
]
