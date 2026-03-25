subnet_id            = "subnet-0cf89c10c198c54fa"
ami_name             = "prodeu-cylon-copied-ami"
key_name             = "prodeu-cylon"
instances_count      = 3
datadog_policy_arn   = "arn:aws:iam::300878470238:policy/prodeu-cylon-datadog"
rds_read_policy_arn  = "arn:aws:iam::300878470238:policy/prodeu-cylon-db-ro-secrets"
ecr_pull_policy_arn  = "arn:aws:iam::300878470238:policy/prodeu-cylon-ecr-ro"
sqs_policy_arn       = "arn:aws:iam::300878470238:policy/prodeu-cylon-sqs-secrets"

extra_disks = [
  { device = "/dev/xvdf", size_gib = 500 },   # existing volumes will be preserved
  { device = "/dev/xvdg", size_gib = 1024 },   # new volumes 1 TiB
  { device = "/dev/xvdh", size_gib = 2048 }
]
