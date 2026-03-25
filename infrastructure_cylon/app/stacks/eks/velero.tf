resource "helm_release" "velero" {
  name             = "vmware-tanzu"
  repository       = "https://vmware-tanzu.github.io/helm-charts"
  chart            = "velero"
  namespace        = "velero"
  version          = "6.0.0"
  create_namespace = true
  values = [
    "${file("velero.yaml")}"
  ]
  set {
    name  = "configuration.backupStorageLocation[0].provider"
    value = "aws"
  }
  set {
    name  = "configuration.volumeSnapshotLocation[0].provider"
    value = "aws"
  }
  set {
    name  = "configuration.backupStorageLocation[0].name"
    value = "default"
  }
  set {
    name  = "configuration.backupStorageLocation[0].bucket"
    value = aws_s3_bucket.velero-s3.bucket
  }
  set {
    name  = "configuration.backupStorageLocation[0].default"
    value = "true"
  }
  set {
    name  = "configuration.backupStorageLocation[0].config.region"
    value = var.region
  }
  set {
    name  = "configuration.backupStorageLocation[0].config.serverSideEncryption"
    value = "AES256"
  }
}

resource "aws_s3_bucket" "velero-s3" {
  bucket = "velero-backup-${var.cluster_name}"
  force_destroy = true
  tags = local.tags
}

resource "aws_s3_bucket_ownership_controls" "velero-s3-controls" {
  bucket = aws_s3_bucket.velero-s3.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "velero-s3-acl" {
  depends_on = [aws_s3_bucket_ownership_controls.velero-s3-controls]
  bucket = aws_s3_bucket.velero-s3.id
  acl    = "private"
}

output "s3_velero" {
  value = aws_s3_bucket.velero-s3.arn
}
