resource "aws_kms_key" "vault" {
  description = "KMS Key for vault unseal"
}

resource "aws_kms_alias" "vault" {
  name          = "alias/vault-${local.eks_cluster_name}"
  target_key_id = aws_kms_key.vault.key_id
}
