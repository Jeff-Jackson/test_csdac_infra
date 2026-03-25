#!/bin/bash

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <action> <prefix> <group>"
    exit 1
fi

ACTION=$1
PREFIX=$2
GROUP=$3

if [[ "$ACTION" != "apply" && "$ACTION" != "delete" ]]; then
    echo "Invalid action. Use 'apply' or 'delete'."
    exit 1
fi

if [[ ! "$GROUP" =~ ^system:[a-zA-Z0-9_-]+$ ]]; then
    echo "Invalid GROUP format. It must be in the format 'system:groupname'."
    exit 1
fi

CONFIGMAP=$(kubectl get configmap aws-auth -n kube-system -o yaml)

if echo "$CONFIGMAP" | grep -q "$GROUP"; then
    echo "Group '$GROUP' exists in the aws-auth ConfigMap."
else
    echo "Group '$GROUP' does not exist in the aws-auth ConfigMap."
    exit 1
fi

METADATA_GROUP=$(echo "$GROUP" | sed 's/://g')
KIND_GROUP=$(echo "$GROUP" | sed 's/://g' | awk '{print toupper(substr($0,1,1)) tolower(substr($0,2))}')


cat <<EOF > cluster-role.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: "${METADATA_GROUP}NamespaceClusterRole"
rules:
- apiGroups: ["*"]
  resources: ["*"]
  verbs: ["*"]
EOF


cat <<EOF > cluster-role-binding.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: "${METADATA_GROUP}NamespaceClusterRole-binding"
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: "${METADATA_GROUP}NamespaceClusterRole"
subjects:
- kind: Group
  name: "${GROUP}"
  apiGroup: rbac.authorization.k8s.io
EOF


cat <<EOF > constraint-template-resources.yaml
apiVersion: templates.gatekeeper.sh/v1beta1
kind: ConstraintTemplate
metadata:
  name: ${METADATA_GROUP}resourceinnamespaceprefix
spec:
  crd:
    spec:
      names:
        kind: ${KIND_GROUP}ResourceInNamespacePrefix
      validation:
        openAPIV3Schema:
          properties:
            prefix:
              type: string
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package ${METADATA_GROUP}resourceinnamespaceprefix

        violation[{"msg": msg}] {
          input.review.kind.kind != "Namespace"
          namespace := input.review.object.metadata.namespace
          user_groups := input.review.userInfo.groups

          user_in_group(user_groups, "$GROUP")
          not startswith(namespace, input.parameters.prefix)

          msg := sprintf("Action is not allowed in namespaces that do not start with '%s'. Namespace: %s, User: %s, Groups: %v", [input.parameters.prefix, namespace, input.review.userInfo.username, input.review.userInfo.groups])
        }

        user_in_group(user_groups, group) {
          group == user_groups[_]
        }
EOF

cat <<EOF > constraint-template-namespaces.yaml
apiVersion: templates.gatekeeper.sh/v1beta1
kind: ConstraintTemplate
metadata:
  name: ${METADATA_GROUP}namespaceprefix
spec:
  crd:
    spec:
      names:
        kind: ${KIND_GROUP}NamespacePrefix
      validation:
        openAPIV3Schema:
          properties:
            prefix:
              type: string
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package ${METADATA_GROUP}namespaceprefix

        violation[{"msg": msg}] {
          input.review.kind.kind == "Namespace"
          name := input.review.object.metadata.name
          user_groups := input.review.userInfo.groups
 
          user_in_group(user_groups, "$GROUP")
          not startswith(name, input.parameters.prefix)
 
          msg := sprintf("Namespace name must start with '%s'. User: %s, Groups: %v", [input.parameters.prefix, input.review.userInfo.username, input.review.userInfo.groups])
        }
 
        user_in_group(user_groups, group) {
          group == user_groups[_]
        }
EOF

cat <<EOF > constraint-resource-prefix.yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: ${KIND_GROUP}NamespacePrefix
metadata:
  name: ns-must-have-prefix
spec:
  match:
    kinds:
      - apiGroups: [""]
        kinds: ["Namespace"]
  parameters:
    prefix: "$PREFIX"
EOF

cat <<EOF > constraint-namespace-prefix.yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: ${KIND_GROUP}ResourceInNamespacePrefix
metadata:
  name: resource-namespace-prefix
spec:
  match:
    kinds:
      - apiGroups: [""]
        kinds: ["*"]
      - apiGroups: ["*"]
        kinds: ["*"]
  parameters:
    prefix: "$PREFIX"
EOF


if [ "$ACTION" == "apply" ]; then
    kubectl $ACTION -f cluster-role.yaml
    kubectl $ACTION -f cluster-role-binding.yaml
    kubectl $ACTION -f constraint-template-resources.yaml
    kubectl $ACTION -f constraint-template-namespaces.yaml
    kubectl $ACTION -f constraint-namespace-prefix.yaml
    kubectl $ACTION -f constraint-resource-prefix.yaml
elif [ "$ACTION" == "delete" ]; then
    kubectl $ACTION -f constraint-resource-prefix.yaml
    kubectl $ACTION -f constraint-namespace-prefix.yaml
    kubectl $ACTION -f constraint-template-namespaces.yaml
    kubectl $ACTION -f constraint-template-resources.yaml
    kubectl $ACTION -f cluster-role-binding.yaml
    kubectl $ACTION -f cluster-role.yaml
fi

kubectl get constrainttemplates

rm cluster-role.yaml cluster-role-binding.yaml constraint-template-resources.yaml constraint-template-namespaces.yaml constraint-namespace-prefix.yaml constraint-resource-prefix.yaml

echo "All files have been successfully applied."
