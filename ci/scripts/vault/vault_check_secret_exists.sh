#!/bin/bash -l
set -euo pipefail

# Required env vars:
#   AWS_REGION
#   VAULT_SECRET_VAR_NAME

if aws secretsmanager describe-secret --secret-id "${VAULT_SECRET_VAR_NAME}" --region "${AWS_REGION}" >/dev/null 2>&1; then
  echo "ERROR: Secret ${VAULT_SECRET_VAR_NAME} already exists in Secrets Manager. Refusing to overwrite. If you REALLY intend to overwrite, set VAULT_INIT_FORCE_OVERWRITE_AWS_SM=true."
  exit 2
fi

echo "Secret ${VAULT_SECRET_VAR_NAME} does not exist, safe to proceed."
