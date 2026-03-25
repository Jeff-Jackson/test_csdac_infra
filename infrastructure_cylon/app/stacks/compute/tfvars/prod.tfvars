subnet_id            = "subnet-0747b270390d04132"
ami_name             = "cylon-dd-prod"
key_name             = "cylon-ass-us-west-1"
instances_count      = 3
datadog_policy_arn   = "arn:aws:iam::300878470238:policy/prod-cylon-datadog"
rds_read_policy_arn  = "arn:aws:iam::300878470238:policy/prod-cylon-db-ro-secrets"
ecr_pull_policy_arn  = "arn:aws:iam::300878470238:policy/prod-cylon-ecr-ro"
sqs_policy_arn       = "arn:aws:iam::300878470238:policy/prod-cylon-sqs-secrets"

# --- EC2 instances managed by Terraspace ---
  { device = "/dev/xvdf", size_gib = 500 },   # existing volumes will be preserved
  { device = "/dev/xvdg", size_gib = 1024 },   # new volumes 1 TiB
  { device = "/dev/xvdh", size_gib = 2048 }
]

# --- Legacy instance (prod-cylon, managed separately) ---
legacy_instance_name     = "prod-cylon"

# new 2 TB disk for legacy instance
legacy_extra_disk_device = "/dev/xvdi"
legacy_extra_disk_size   = 2048
legacy_extra_disk_tags   = {
  purpose = "legacy-data"
}
