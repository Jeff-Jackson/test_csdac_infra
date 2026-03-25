#!/bin/bash -l
set -euo pipefail

# Required env vars:
#   AWS_REGION, ENVIRONMENT, BACKUP_TAG
#   VAULT_TLS_SECRET_NAME, VAULT_TLS_SECRET_NAMESPACE, TLS_BACKUP_SECRET_ID
#
# Note: DynamoDB backup is handled automatically by AWS Backup (hourly) + PITR.
#       This script only backs up TLS certificates before renewal.

ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
VAULT_BACKUP_S3_BUCKET="csdac-vault-backups-${ENVIRONMENT}-${ACCOUNT_ID}-${AWS_REGION}"
VAULT_BACKUP_S3_PREFIX="vault/${ENVIRONMENT}/${AWS_REGION}/${BACKUP_TAG}"

echo "Checking S3 bucket exists: ${VAULT_BACKUP_S3_BUCKET}"
aws s3api head-bucket --bucket "${VAULT_BACKUP_S3_BUCKET}" >/dev/null

aws eks update-kubeconfig --region "${AWS_REGION}" --name "csdac-${ENVIRONMENT}-cluster" >/dev/null

echo "Backing up current Vault TLS secret (${VAULT_TLS_SECRET_NAMESPACE}/${VAULT_TLS_SECRET_NAME}) to Secrets Manager: ${TLS_BACKUP_SECRET_ID}"
kubectl get secret "${VAULT_TLS_SECRET_NAME}" -n "${VAULT_TLS_SECRET_NAMESPACE}" -o json \
  | jq -c '{
      captured_at: (now | todate),
      cluster: "csdac-'"${ENVIRONMENT}"'-cluster",
      environment: "'"${ENVIRONMENT}"'",
      region: "'"${AWS_REGION}"'",
      build: "'"${BACKUP_TAG}"'",
      secret_type: .type,
      data: .data
    }' > vault-tls-backup.json

aws secretsmanager create-secret --name "${TLS_BACKUP_SECRET_ID}" --region "${AWS_REGION}" >/dev/null 2>&1 || true
aws secretsmanager put-secret-value --secret-id "${TLS_BACKUP_SECRET_ID}" --secret-string file://vault-tls-backup.json --region "${AWS_REGION}" > tls-backup-put.json
cat tls-backup-put.json

echo "TLS backup stored. VersionId: $(jq -r '.VersionId' tls-backup-put.json)"

jq -n \
  --arg captured_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --arg cluster "csdac-${ENVIRONMENT}-cluster" \
  --arg environment "${ENVIRONMENT}" \
  --arg region "${AWS_REGION}" \
  --arg build "${BACKUP_TAG}" \
  --arg tls_backup_secret_id "${TLS_BACKUP_SECRET_ID}" \
  --arg tls_backup_version_id "$(jq -r '.VersionId' tls-backup-put.json)" \
  --arg s3_bucket "${VAULT_BACKUP_S3_BUCKET}" \
  --arg s3_prefix "${VAULT_BACKUP_S3_PREFIX}" \
  '{captured_at:$captured_at,cluster:$cluster,environment:$environment,region:$region,build:$build,tls:{backup_secret_id:$tls_backup_secret_id,backup_version_id:$tls_backup_version_id},s3:{bucket:$s3_bucket,prefix:$s3_prefix}}' \
  > backup-manifest.json

echo "Extracting TLS certificates from backup..."
jq -r '.data["tls.crt"]' vault-tls-backup.json | base64 -d > tls.crt
jq -r '.data["tls.key"]' vault-tls-backup.json | base64 -d > tls.key
jq -r '.data["ca.crt"]' vault-tls-backup.json | base64 -d > ca.crt

echo "Uploading backup artifacts to s3://${VAULT_BACKUP_S3_BUCKET}/${VAULT_BACKUP_S3_PREFIX}/"
aws s3 cp backup-manifest.json "s3://${VAULT_BACKUP_S3_BUCKET}/${VAULT_BACKUP_S3_PREFIX}/backup-manifest.json" --only-show-errors
aws s3 cp vault-tls-backup.json "s3://${VAULT_BACKUP_S3_BUCKET}/${VAULT_BACKUP_S3_PREFIX}/vault-tls-backup.json" --only-show-errors
aws s3 cp tls.crt "s3://${VAULT_BACKUP_S3_BUCKET}/${VAULT_BACKUP_S3_PREFIX}/tls.crt" --only-show-errors
aws s3 cp tls.key "s3://${VAULT_BACKUP_S3_BUCKET}/${VAULT_BACKUP_S3_PREFIX}/tls.key" --only-show-errors
aws s3 cp ca.crt "s3://${VAULT_BACKUP_S3_BUCKET}/${VAULT_BACKUP_S3_PREFIX}/ca.crt" --only-show-errors

rm -f tls.crt tls.key ca.crt

echo "Pre-flight backup completed successfully."
