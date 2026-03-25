# Terraform Vault Deployment to AWS EKS

## Overview

This repository provides a Terraform-based deployment of HashiCorp Vault on AWS EKS, using Helm charts for Vault installation and configuration. The deployment and ongoing operations are primarily orchestrated via a Jenkins pipeline, which automates infrastructure provisioning, Vault initialization, and configuration tasks. While manual Terraform CLI usage is supported for debugging and troubleshooting, the Jenkins pipeline is the recommended approach for consistent and repeatable deployments.

### 1. Project Initialization  
**(Manual / Local Terraform - rare, for debugging only)**

```
export CSDAC_ENV=dev # Env type
aws configure # if not configured AWS credentials
# Init Terraform backend for each Env
terraform init -backend-config="key=terraform/vault-$CSDAC_ENV/terraform.tfstate"
```

### 2. Variable configuration  
**(Manual / Local Terraform - rare, for debugging only)**

```
# Get EKS context
aws eks update-kubeconfig --region us-west-1 --name csdac-$CSDAC_ENV-cluster
# Export variables
export TF_VAR_region=us-west-1 TF_VAR_env=$CSDAC_ENV TF_VAR_kubectl_ctx=$(kubectl config current-context) TF_VAR_kubectl_CA=$(kubectl config view --minify --raw --output 'jsonpath={..cluster.certificate-authority-data}')
```

### 3. Start Deploy  
**(Manual / Local Terraform - rare, for debugging only)**

```
terraform apply
```

### 4. Vault configuration  
**(Manual / Local Terraform - rare, for debugging only)**

```
# Connect to pod vault-0 in vault namespace
vault operator init -tls-skip-verify # Save a output!
vault login # put a `Initial Root Token:` from prev command
vault auth enable kubernetes
vault write auth/kubernetes/config \
     kubernetes_host="https://$KUBERNETES_PORT_443_TCP_ADDR:443" \
     token_reviewer_jwt="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" \
     kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt \
     issuer="https://kubernetes.default.svc.cluster.local"
vault auth enable approle
vault auth enable aws
```

## Jenkins Pipeline Usage (Recommended)

The Jenkins pipeline automates Vault deployment and management tasks, providing parameters to control Terraform execution, Vault initialization, and configuration.

### Parameters

- **AWS_CREDENTIALS** – Jenkins credential ID for AWS account  
- **ENVIRONMENT** – Environment name (dev / qa / stage / prod)  
- **AWS_REGION** – AWS region where EKS and Vault backend live  
- **TF_RUN** – Enable Terraform execution  
- **ACTION** – Terraform action: plan / apply / destroy  
- **VAULT_OPERATOR_INIT** – Run `vault operator init` (one-time only)  
- **VAULT_CONFIGURE** – Run logical Vault configuration (`vault_configure.sh`)  
- **VAULT_UPDATE_TLS_CERT** – Force TLS certificate re-issue  
- **AWS_SM** – Read root token from AWS Secrets Manager (recommended)  
- **VAULT_ROOT_TOKEN** – Manual root token (emergency use only)  

### Common Run Scenarios

#### 1. Normal update (Helm / IRSA / Terraform changes)  
- TF_RUN = true  
- ACTION = apply  
- All VAULT_* flags = false  

#### 2. First-time Vault deployment (new environment)  

Step 1 – Infrastructure:  
- TF_RUN = true  
- ACTION = apply  

Step 2 – Initialize Vault:  
- VAULT_OPERATOR_INIT = true  

Step 3 – Configure Vault:  
- VAULT_CONFIGURE = true  
- AWS_SM = true  

#### 3. Update Vault configuration only (policies, auth, engines)  
- TF_RUN = false  
- VAULT_CONFIGURE = true  
- AWS_SM = true  

#### 4. Re-issue Vault TLS certificate  
- TF_RUN = true  
- VAULT_UPDATE_TLS_CERT = true  
- ACTION = apply  

#### 5. Terraform plan (no changes)  
- TF_RUN = true  
- ACTION = plan  

#### 6. Destroy environment (dangerous)  
- TF_RUN = true  
- ACTION = destroy  

## Important Notes

- `vault operator init` must be executed only once per storage backend
- Vault initialization is required **only** when deploying Vault to a **new EKS cluster with a new DynamoDB storage backend**
- If Vault already exists in the cluster (even after upgrades, restarts, or failures), **initialization must NOT be re-run**
- Root token and unseal keys are stored in AWS Secrets Manager  
- Jenkins workspace is ephemeral; do not rely on local files  
- Vault uses IRSA; node IAM role must NOT be required  
- DynamoDB + KMS backend allows safe EKS upgrades  

## Recommended Default

```
TF_RUN = true
ACTION = apply
(all VAULT_* flags disabled)
```
