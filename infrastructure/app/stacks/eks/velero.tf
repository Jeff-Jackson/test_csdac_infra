resource "helm_release" "velero" {
  name             = "vmware-tanzu"
  repository       = "https://vmware-tanzu.github.io/helm-charts"
  chart            = "velero"
  namespace        = "velero"
  version          = "6.2.0"
  create_namespace = true
  timeout          = 1800
  atomic           = true
  cleanup_on_fail  = true
  depends_on       = [aws_s3_bucket.velero-s3]
  values = [
    templatefile("${path.module}/velero.yaml", {
      VELERO_BUCKET = aws_s3_bucket.velero-s3.bucket
      VELERO_REGION = var.region
    })
  ]
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
