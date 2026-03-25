#!/bin/bash -l
set -euo pipefail
CLUSTER_NAME="csdac-${ENVIRONMENT}-cluster"
REGION="${AWS_REGION}"

echo "Configuring kubeconfig for ${CLUSTER_NAME} in ${REGION} ..."
aws eks update-kubeconfig --name "${CLUSTER_NAME}" --region "${REGION}" >/dev/null

echo "Uninstalling Helm releases if present..."
# Helm v3 uninstall (without hooks, so it doesn't crash due to outdated resources)
helm -n kube-system uninstall cluster-autoscaler --no-hooks || true
helm -n kube-system uninstall aws-node-termination-handler --no-hooks || true

# Remove helm secrets (in case of partially corrupted release history)
kubectl -n kube-system delete secret -l 'owner=helm,name=cluster-autoscaler' --ignore-not-found
kubectl -n kube-system delete secret -l 'owner=helm,name=aws-node-termination-handler' --ignore-not-found

echo "Deleting leftover Kubernetes objects by labels..."
# Cluster Autoscaler: remove everything that could remain from the old chart
kubectl -n kube-system delete deploy,rs,po,cm,svc,sa -l \
  'app.kubernetes.io/name=aws-cluster-autoscaler,app.kubernetes.io/instance=cluster-autoscaler' \
  --ignore-not-found

# And obvious names from old releases (in case of missing labels)
kubectl -n kube-system delete deploy cluster-autoscaler-aws-cluster-autoscaler --ignore-not-found
kubectl -n kube-system delete sa cluster-autoscaler-aws --ignore-not-found

# The old PDB CA (the one that shows up in the policy/v1beta1 error)
kubectl -n kube-system delete pdb cluster-autoscaler-aws-cluster-autoscaler --ignore-not-found

# Node Termination Handler: remove everything by labels and names
kubectl -n kube-system delete deploy,rs,po,cm,svc,sa -l \
  'app.kubernetes.io/name=aws-node-termination-handler,app.kubernetes.io/instance=aws-node-termination-handler' \
  --ignore-not-found
kubectl -n kube-system delete deploy aws-node-termination-handler --ignore-not-found
kubectl -n kube-system delete sa aws-node-termination-handler --ignore-not-found

# Old PSP from the NTH chart (cluster resource)
kubectl delete podsecuritypolicy.policy aws-node-termination-handler --ignore-not-found || true

echo "Waiting for leftovers to disappear..."
kubectl -n kube-system wait --for=delete pod -l \
 'app.kubernetes.io/name in (aws-cluster-autoscaler,aws-node-termination-handler)' \
 --timeout=60s || true

echo "Post-clean snapshot:"
kubectl -n kube-system get deploy,po,pdb,sa | grep -E 'autoscaler|termination|NAME' || true
echo "Helm pre-clean done."
