### Creating a KMS keys for AWS Backup Vault
resource "aws_kms_key" "vaultdb" {
  description = "KMS Key for AWS Backup Vault"
}

resource "aws_kms_alias" "vaultdb" {
  name          = format("alias/vault-%s-backup", var.env)
  target_key_id = aws_kms_key.vaultdb.key_id
}

resource "aws_backup_vault" "vaultdb" {
  name        = format("vault-%s-backup-vault", var.env)
  kms_key_arn = aws_kms_key.vaultdb.arn
}

resource "aws_backup_plan" "vaultdb" {
  name = format("vault-%s-backup-plan", var.env)

  rule {
    rule_name         = format("vault-%s-backup-rule", var.env)
    target_vault_name = aws_backup_vault.vaultdb.name
    schedule          = "cron(0 5/1 ? * * *)" # hourly backup

    lifecycle {
      delete_after = 14
    }
  }
}

resource "aws_iam_role" "vaulddb" {
  name               = format("vault-%s-backup-role", var.env)
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": ["sts:AssumeRole"],
      "Effect": "allow",
      "Principal": {
        "Service": ["backup.amazonaws.com"]
      }
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "vaultdb" {
  policy_arn = "arn:${var.arn}:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
  role       = aws_iam_role.vaulddb.name
}

resource "aws_backup_selection" "vaultdb" {
  iam_role_arn = aws_iam_role.vaulddb.arn
  name         = format("vault-%s-backup-selection", var.env)
  plan_id      = aws_backup_plan.vaultdb.id

  resources = [
    aws_dynamodb_table.dynamodb-table.arn
  ]
}
