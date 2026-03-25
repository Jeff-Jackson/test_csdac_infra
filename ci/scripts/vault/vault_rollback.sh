#!/bin/bash -l
set -euo pipefail

# Vault TLS Certificate Rollback Script
# Restores TLS certificate from AWS Secrets Manager backup
#
# Required env vars:
#   AWS_REGION, ENVIRONMENT
#   VAULT_TLS_SECRET_NAME, VAULT_TLS_SECRET_NAMESPACE, TLS_BACKUP_SECRET_ID
#
# Optional env vars:
#   ROLLBACK_TLS_VERSION_ID (to restore specific TLS version from Secrets Manager)

aws eks update-kubeconfig --region "${AWS_REGION}" --name "csdac-${ENVIRONMENT}-cluster" >/dev/null

echo "Restoring Vault TLS secret from Secrets Manager: ${TLS_BACKUP_SECRET_ID}"
if [ -n "${ROLLBACK_TLS_VERSION_ID:-}" ]; then
  echo "Using specific version: ${ROLLBACK_TLS_VERSION_ID}"
  aws secretsmanager get-secret-value --secret-id "${TLS_BACKUP_SECRET_ID}" --version-id "${ROLLBACK_TLS_VERSION_ID}" --region "${AWS_REGION}" --query SecretString --output text > vault-tls-backup.json
else
  echo "Using latest version (AWSCURRENT)"
  aws secretsmanager get-secret-value --secret-id "${TLS_BACKUP_SECRET_ID}" --region "${AWS_REGION}" --query SecretString --output text > vault-tls-backup.json
fi

kubectl apply -f <(jq -c '{
  apiVersion: "v1",
  kind: "Secret",
  metadata: { name: "'"${VAULT_TLS_SECRET_NAME}"'", namespace: "'"${VAULT_TLS_SECRET_NAMESPACE}"'" },
  type: .secret_type,
  data: .data
}' vault-tls-backup.json)

echo "TLS secret restored. Restarting Vault pod vault-0 to pick up TLS changes."
kubectl -n "${VAULT_TLS_SECRET_NAMESPACE}" delete pod vault-0 --ignore-not-found

rm -f vault-tls-backup.json

echo "TLS rollback completed successfully."
