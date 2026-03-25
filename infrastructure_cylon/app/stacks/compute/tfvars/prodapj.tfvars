subnet_id            = "subnet-0d0bd29496677a652"
ami_name             = "prodapj-cylon-copied-ami"
key_name             = "prodapj-cylon"
instances_count      = 3
datadog_policy_arn   = "arn:aws:iam::300878470238:policy/prodapj-cylon-datadog"
rds_read_policy_arn  = "arn:aws:iam::300878470238:policy/prodapj-cylon-db-ro-secrets"
ecr_pull_policy_arn  = "arn:aws:iam::300878470238:policy/prodapj-cylon-ecr-ro"
sqs_policy_arn       = "arn:aws:iam::300878470238:policy/prodapj-cylon-sqs-secrets"

extra_disks = [
  { device = "/dev/xvdf", size_gib = 500 },   # existing volumes will be preserved
  { device = "/dev/xvdg", size_gib = 1024 }   # new volumes 1 TiB
]
