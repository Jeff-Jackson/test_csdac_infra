resource "aws_kms_key" "vault_backup_bucket" {
  description = "KMS Key for Vault backup S3 bucket"
}

resource "aws_kms_alias" "vault_backup_bucket" {
  name          = format("alias/vault-%s-backup-bucket", var.env)
  target_key_id = aws_kms_key.vault_backup_bucket.key_id
}

resource "aws_s3_bucket" "vault_backup" {
  bucket = format("csdac-vault-backups-%s-%s-%s", var.env, local.account_id, var.region)

  tags = merge(
    local.tags,
    {
      Name = format("csdac-vault-backups-%s-%s-%s", var.env, local.account_id, var.region)
    }
  )
}

resource "aws_s3_bucket_versioning" "vault_backup" {
  bucket = aws_s3_bucket.vault_backup.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "vault_backup" {
  bucket = aws_s3_bucket.vault_backup.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "vault_backup" {
  bucket = aws_s3_bucket.vault_backup.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.vault_backup_bucket.arn
    }
  }
}

data "aws_iam_policy_document" "vault_backup_bucket_policy" {
  statement {
    sid     = "DenyInsecureTransport"
    effect  = "Deny"
    actions = ["s3:*"]

    resources = [
      aws_s3_bucket.vault_backup.arn,
      "${aws_s3_bucket.vault_backup.arn}/*"
    ]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  statement {
    sid    = "AllowVaultBackupReadWrite"
    effect = "Allow"

    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:PutObject",
      "s3:AbortMultipartUpload",
      "s3:ListBucketMultipartUploads",
      "s3:ListMultipartUploadParts"
    ]

    resources = [
      aws_s3_bucket.vault_backup.arn,
      "${aws_s3_bucket.vault_backup.arn}/*"
    ]

    principals {
      type = "AWS"
      identifiers = concat(
        [
          format("arn:%s:iam::%s:root", var.arn, local.account_id),
          format("arn:%s:iam::%s:user/terraform", var.arn, local.account_id)
        ],
        var.vault_backup_additional_principals
      )
    }
  }
}

resource "aws_s3_bucket_policy" "vault_backup" {
  bucket = aws_s3_bucket.vault_backup.id
  policy = data.aws_iam_policy_document.vault_backup_bucket_policy.json
}
