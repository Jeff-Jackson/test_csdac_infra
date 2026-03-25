resource "kubernetes_namespace" "vault" {
  metadata {
    name = "vault"
  }
}

data "aws_caller_identity" "current" {}

data "aws_eks_cluster" "csdac" {
  name = local.eks_cluster_name
}

locals {
  eks_cluster_name = var.eks_cluster_name != "" ? var.eks_cluster_name : "csdac-${var.env}-cluster"
  account_id       = data.aws_caller_identity.current.account_id
  cidc_id          = split("/", data.aws_eks_cluster.csdac.identity[0].oidc[0].issuer)[4]
  tags = {
    DataClassification = "Cisco Highly Confidential"
    ApplicationName    = "CSDAC"
    ResourceOwner      = "SBG"
    CiscoMailAlias     = "dbudko@cisco.com"
    DataTaxonomy       = "CustomerData+AdministrativeData"
    EnvironmentName    = format("csdac-%s-cluster", var.env)
    Environment        = var.env
    Terraform          = "true"
  }
}

# --- IRSA prerequisite: ensure correct IAM OIDC provider exists for this EKS cluster ---

# EKS exposes OIDC issuer like: https://oidc.eks.<region>.amazonaws.com/id/<id>
# IAM OIDC provider "url" expects without scheme: oidc.eks.<region>.amazonaws.com/id/<id>
locals {
  oidc_issuer_url         = data.aws_eks_cluster.csdac.identity[0].oidc[0].issuer
  oidc_issuer_hostpath    = replace(local.oidc_issuer_url, "https://", "")
  oidc_provider_arn       = "arn:${var.arn}:iam::${local.account_id}:oidc-provider/${local.oidc_issuer_hostpath}"
}

# Fetch issuer certificate chain to calculate thumbprint for IAM OIDC provider
data "tls_certificate" "oidc" {
  url = data.aws_eks_cluster.csdac.identity[0].oidc[0].issuer
}

# Create the correct IAM OIDC provider for IRSA (if it doesn't exist yet in this account)
resource "aws_iam_openid_connect_provider" "eks" {
  url             = data.aws_eks_cluster.csdac.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.oidc.certificates[0].sha1_fingerprint]

  tags = local.tags
}

resource "aws_iam_role" "vault_irsa_role" {
  name = "csdac-${var.env}-vault-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.eks.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "oidc.eks.${var.region}.amazonaws.com/id/${local.cidc_id}:aud" = "sts.amazonaws.com"
            "oidc.eks.${var.region}.amazonaws.com/id/${local.cidc_id}:sub" = "system:serviceaccount:vault:vault-server-sa"
          }
        }
      }
    ]
  })

  tags = local.tags
}

resource "aws_iam_policy" "csdac_vault_policy_getrole" {
  count       = var.arn == "aws-us-gov" ? 1 : 0
  name        = "csdac-${var.env}-getrole-vault-policy"
  description = "CSDAC EC2 Policy for Vault EKS Cluster"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "iam:GetRole"
            ],
            "Resource": [
                "arn:${var.arn}:iam::${local.account_id}:role/Lambda-CDO-${var.env}-role",
                "arn:${var.arn}:iam::${local.account_id}:role/Lambda-CDO-remove-${var.env}-role",
                "arn:${var.arn}:iam::${local.account_id}:role/Lambda-CDO-${local.eks_cluster_name}-role",
                "arn:${var.arn}:iam::${local.account_id}:role/Lambda-CDO-remove-${local.eks_cluster_name}-role"
            ]
        }
      ]
}
EOF
}

resource "aws_iam_policy" "vault_storage_policy" {
  name        = "csdac-${var.env}-vault-storage-policy"
  description = "Vault IRSA policy: DynamoDB storage + KMS unseal"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "VaultDynamoDBStorage"
        Effect = "Allow"
        Action = [
          "dynamodb:DescribeTable",
          "dynamodb:GetItem",
          "dynamodb:BatchGetItem",
          "dynamodb:PutItem",
          "dynamodb:BatchWriteItem",
          "dynamodb:DeleteItem",
          "dynamodb:UpdateItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = aws_dynamodb_table.dynamodb-table.arn
      },
      {
        Sid    = "VaultKMSUnseal"
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:DescribeKey",
          "kms:GenerateDataKey"
        ]
        Resource = aws_kms_key.vault.arn
      }
    ]
  })

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "vault_storage_policy_attachment" {
  role       = aws_iam_role.vault_irsa_role.name
  policy_arn = aws_iam_policy.vault_storage_policy.arn
}

resource "aws_iam_role_policy_attachment" "getrole_access_policy_attachment" {
  count      = var.arn == "aws-us-gov" ? 1 : 0
  role       = aws_iam_role.vault_irsa_role.name
  policy_arn = aws_iam_policy.csdac_vault_policy_getrole[0].arn
}

resource "aws_dynamodb_table" "dynamodb-table" {
  name           = "vault-${local.eks_cluster_name}"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "Path"
  range_key      = "Key"

  point_in_time_recovery {
    enabled = true
  }

  attribute {
    name = "Path"
    type = "S"
  }

  attribute {
    name = "Key"
    type = "S"
  }

  tags = {
    map-migrated = "mig46775"
  }
}

resource "helm_release" "vault" {
  repository = "https://helm.releases.hashicorp.com"
  chart      = "vault"
  name       = "vault"
  version    = "0.29.1"
  namespace  = kubernetes_namespace.vault.metadata[0].name

  # Helm provider default timeout is often too low for Vault upgrades (pods restart, leader election, etc.)
  # Keep wait=true for correctness; increase timeout to avoid false failures.
  wait    = true
  timeout = 1800

  # Safer upgrade semantics: rollback/uninstall on failed upgrade instead of leaving a failed release.
  atomic          = true
  cleanup_on_fail = true

  values = [
    templatefile(
      var.arn == "aws" ? "${path.module}/config/vault.tmpl" : "${path.module}/config/vault_gov.tmpl",
      merge(
        {
          kms_key_id     = aws_kms_key.vault.key_id
          aws_region     = var.region
          dynamodb_table = aws_dynamodb_table.dynamodb-table.name
          role_arn       = aws_iam_role.vault_irsa_role.arn
        }
      )
    )
  ]

  #  lifecycle {
  #    ignore_changes = [keyring]
  #  }
}

resource "helm_release" "csi" {
  repository = "https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts"
  chart      = "secrets-store-csi-driver"
  name       = "secrets-store-csi-driver"
  namespace  = kubernetes_namespace.vault.metadata[0].name
}

resource "tls_private_key" "vault" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_cert_request" "vault" {
  key_algorithm   = "RSA"
  private_key_pem = tls_private_key.vault.private_key_pem
  dns_names       = [
    "vault",
    "vault.vault",
    "vault.vault.svc",
    "vault.vault.svc.cluster.local",
    "vault-active",
    "vault-active.vault",
    "vault-active.vault.svc",
    "vault-active.vault.svc.cluster.local",
    "vault-standby",
    "vault-standby.vault",
    "vault-standby.vault.svc",
    "vault-standby.vault.svc.cluster.local",
    "*.vault-internal",
  ]
  ip_addresses    = ["127.0.0.1"]

  subject {
    common_name  = "system:node:vault.vault.svc"
    organization = "system:nodes"
  }
}

resource "kubernetes_certificate_signing_request_v1" "vault" {
  metadata {
    name = "vault-csr"
  }

  spec {
    usages      = ["digital signature", "key encipherment", "server auth"]
    request     = tls_cert_request.vault.cert_request_pem
    signer_name = "beta.eks.amazonaws.com/app-serving"
  }

  auto_approve = true
}

resource "kubernetes_secret" "vault" {
  metadata {
    name      = "vault-server-tls"
    namespace = "vault"
  }

  data = {
    "vault.crt" = kubernetes_certificate_signing_request_v1.vault.certificate
    "vault.key" = tls_private_key.vault.private_key_pem
    "vault.ca"  = base64decode(var.kubectl_CA)
    #    cluster_ca_certificate
  }
}
