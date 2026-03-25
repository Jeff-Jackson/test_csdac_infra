#!/usr/bin/env sh

vault login $1

vault auth enable kubernetes || true

vault write auth/kubernetes/config \
    kubernetes_host=https://$KUBERNETES_SERVICE_HOST:$KUBERNETES_SERVICE_PORT

#vault write auth/kubernetes/config \
#     kubernetes_host="https://$KUBERNETES_PORT_443_TCP_ADDR:443" \
#     token_reviewer_jwt="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" \
#     kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt \
#     issuer="https://kubernetes.default.svc.cluster.local"

vault secrets enable -tls-skip-verify -version=2 -path=secret kv || true

vault policy write -tls-skip-verify lambda - <<EOF
path "secret/data/*" {
  capabilities = ["create", "update", "read", "delete"]
}
path "secret/metadata/*" {
  capabilities = ["list", "delete"]
}
path "sys/policy/*" {
  capabilities = ["create", "update", "read", "delete"]
}
path "auth/approle/*" {
  capabilities = ["create", "update", "read", "delete", "list"]
}
path "auth/kubernetes/*" {
  capabilities = ["create", "update", "read", "delete"]
}
EOF

vault auth enable -tls-skip-verify approle || true
vault write -tls-skip-verify auth/approle/role/lambda-role-iam token_policies="lambda" \
    token_ttl=15m token_max_ttl=15m
vault write -tls-skip-verify auth/approle/role/lambda-remove-role-iam token_policies="lambda" \
    token_ttl=15m token_max_ttl=15m
vault auth enable -tls-skip-verify aws || true

arn="aws"
if [ "$3" = "us-gov-east-1" ] || [ "$3" = "us-gov-west-1" ]; then
  arn="aws-us-gov"
  vault write auth/aws/config/client sts_endpoint="https://sts.$3.amazonaws.com" sts_region="$3"
fi

account_id="012555280953"
if [ -n "${4:-}" ]; then
  account_id="$4"
elif [ "$2" = "dev" ] || [ "$2" = "qa" ] || [ "$2" = "staging" ] || [ "$2" = "stagingtest" ]; then
  account_id="012555280953"
elif [ "$2" = "stgfed" ] || [ "$2" = "stgfedtest" ]; then
  account_id="167206694810"
elif [ "$2" = "prdfed" ]; then
  account_id="prdfed"
else
  account_id="300878470238"
fi

role_suffix="$2"
if [ -n "${5:-}" ]; then
  role_suffix="$5"
fi

  vault write -tls-skip-verify auth/aws/role/lambda-role-iam auth_type=iam \
      bound_iam_principal_arn=arn:$arn:iam::$account_id:role/Lambda-CDO-$role_suffix-role policies=lambda max_ttl=1h
  vault write -tls-skip-verify auth/aws/role/lambda-remove-role-iam auth_type=iam \
      bound_iam_principal_arn=arn:$arn:iam::$account_id:role/Lambda-CDO-remove-$role_suffix-role policies=lambda max_ttl=1h

# shellcheck disable=SC2039
