locals {
  mariadb_secret_arns = distinct(compact([
    for k, m in module.mariadb :
    try(m.db_instance_master_user_secret_arn, null)
  ]))

  # NEW: collect MySQL secret ARNs across for_each module.db (dedup + no nulls)
  mysql_secret_arns = distinct(compact([
    for k, m in module.db :
    try(m.db_instance_master_user_secret_arn, null)
  ]))
}

resource "aws_iam_policy" "cylon_db_ro_policy" {
  name        = "${local.name}-db-ro-secrets"
  description = "Cylon policy to get rds secrets"

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [policy]
  }

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = concat(
      length(concat(local.mysql_secret_arns, local.mariadb_secret_arns)) > 0 ? [
        {
          Effect   = "Allow",
          Action   = [
            "secretsmanager:GetResourcePolicy",
            "secretsmanager:GetSecretValue",
            "secretsmanager:DescribeSecret",
            "secretsmanager:ListSecretVersionIds"
          ],
          Resource = concat(local.mysql_secret_arns, local.mariadb_secret_arns)
        }
      ] : [],
      [
        {
          Effect   = "Allow",
          Action   = "secretsmanager:ListSecrets",
          Resource = "*"
        }
      ]
    )
  })
}

resource "aws_iam_role" "rds_monitoring" {
  name = "${local.name}-rds-monitoring-role"
  path = "/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = { Service = "monitoring.rds.amazonaws.com" },
        Action   = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(local.tags, { Name = "${local.name}-rds-monitoring-role" })
}

# Attach AWS-managed policy for Enhanced Monitoring
resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}
