resource "aws_security_group" "efs" {
  name        = "${var.cluster_name}-efs"
  description = "Security group for EFS allowing NFS traffic"
  vpc_id      = var.vpc_id

  ingress {
    description      = "nfs"
    from_port        = 2049
    to_port          = 2049
    protocol         = "TCP"
    cidr_blocks      = ["10.221.0.0/16"]
  }
  tags = local.tags
}

resource "aws_efs_file_system" "efs" {
  creation_token = "cylon-eks-efs"
  encrypted      = true
  tags = local.tags
}

resource "aws_efs_mount_target" "mount" {
    file_system_id = aws_efs_file_system.efs.id
    subnet_id = each.key
    for_each = toset(var.private_subnets)
    security_groups = [aws_security_group.efs.id]
}

resource "kubernetes_storage_class" "efs_sc" {
 metadata {
  name = "${local.name}-efs-sc"
 }
 storage_provisioner = "efs.csi.aws.com"
 reclaim_policy      = "Retain"
}

resource "kubernetes_persistent_volume" "cylon_pv" {
  metadata {
    name = "${local.name}-pv"
  }
  spec {
    capacity = {
      storage = "100Gi"
    }
    access_modes = ["ReadWriteMany"]
    persistent_volume_reclaim_policy = "Retain"
    storage_class_name = "${kubernetes_storage_class.efs_sc.metadata.0.name}"
    persistent_volume_source {
      csi {
        driver = "efs.csi.aws.com"
        volume_handle = aws_efs_file_system.efs.id
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "cylon_pvc" {
  metadata {
    name = "${local.name}-pvc"
    namespace = "cylon"
  }
  spec {
    access_modes = ["ReadWriteMany"]
    resources {
      requests = {
        storage = "100Gi"
      }
    }
    storage_class_name = "${kubernetes_storage_class.efs_sc.metadata.0.name}"
    volume_name = "${kubernetes_persistent_volume.cylon_pv.metadata.0.name}"
  }
}
