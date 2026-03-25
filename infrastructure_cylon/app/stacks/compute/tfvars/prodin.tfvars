subnet_id            = "subnet-0d451b89dfad39eda"
ami_name             = "prodin-cylon-copied-ami"
key_name             = "prodin-cylon"
instances_count      = 3
datadog_policy_arn   = "arn:aws:iam::300878470238:policy/prodin-cylon-datadog"
rds_read_policy_arn  = "arn:aws:iam::300878470238:policy/prodin-cylon-db-ro-secrets"
ecr_pull_policy_arn  = "arn:aws:iam::300878470238:policy/prodin-cylon-ecr-ro"
sqs_policy_arn       = "arn:aws:iam::300878470238:policy/prodin-cylon-sqs-secrets"
