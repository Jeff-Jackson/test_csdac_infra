#!/usr/bin/env bash

set -euo pipefail
set -x

STACK_DIR=.terraspace-cache/${AWS_REGION}/${TS_ENV}/stacks/eks
MODULE_DIR=.terraspace-cache/${AWS_REGION}/${TS_ENV}/modules/eks

# Use fixed path instead of searching
EKS_MAIN=".terraspace-cache/${AWS_REGION}/${TS_ENV}/modules/eks/main.tf"
if [[ ! -f "$EKS_MAIN" ]]; then
  echo "ERROR: Expected EKS module main.tf not found: $EKS_MAIN"
  echo "HINT: ensure 'terraspace build' ran and TS_ENV/AWS_REGION are correct."
  exit 1
fi
echo "Targeting EKS module main: $EKS_MAIN"

echo "Found aws_eks_cluster.this in: $EKS_MAIN"

# Debug: show current resource block for visibility (robust)
awk '
  BEGIN{inres=0; depth=0}
  /resource[[:space:]]+"aws_eks_cluster"[[:space:]]+"this"[[:space:]]*\{/ {
    print "----- BEGIN current aws_eks_cluster.this -----"; inres=1; depth=1; print; next
  }
  {
    if (inres==1) {
      print
      for (i=1;i<=length($0);i++){ c=substr($0,i,1); if(c=="{") depth++; else if(c=="}") depth--; }
      if (depth<=0) { print "----- END current aws_eks_cluster.this -----"; inres=0 }
    }
  }
' "$EKS_MAIN" || true

# If nothing printed, show grep marker and head for context
if ! grep -n 'resource "aws_eks_cluster" "this"' "$EKS_MAIN"; then
  echo "(marker not found) showing first 200 lines for context:"; sed -n '1,200p' "$EKS_MAIN"
fi

# Always normalize lifecycle: remove any existing lifecycle{...} inside aws_eks_cluster.this and inject canonical ignore_changes
cat > /tmp/normalize_eks_lifecycle.awk <<'AWK'
BEGIN {
  inres=0; depth=0; inserted=0;
  in_lc=0; lc_depth=0;           # track existing lifecycle block to remove
  in_dep=0; dep_depth=0;         # track depends_on array [] to insert after
}
{
  line=$0

  # Outside resource: look for start
  if (inres==0) {
    if (match(line, /resource[[:space:]]+"aws_eks_cluster"[[:space:]]+"this"[[:space:]]*\{/)) {
      inres=1; depth=1; print line; next
    }
    print line; next
  }

  # Compute resource-level brace counts for this line up-front
  opens=0; closes=0
  for (i=1; i<=length(line); i++) { ch=substr(line,i,1); if (ch=="{") opens++; else if (ch=="}") closes++ }
  depth_after = depth + opens - closes

  # If currently skipping an existing lifecycle block, still maintain resource depth
  if (in_lc==1) {
    # Track lifecycle-local depth (for correctness) and also update resource depth
    for (i=1; i<=length(line); i++) { ch=substr(line,i,1); if (ch=="{") lc_depth++; else if (ch=="}") lc_depth-- }
    if (lc_depth<=0) { in_lc=0 }
    # End-of-resource check while skipping (rare, but be safe)
    if (depth_after==0 && !inserted) {
      print "  lifecycle {"
      print "    ignore_changes = ["
      print "      access_config[0].bootstrap_cluster_creator_admin_permissions,"
      print "      bootstrap_self_managed_addons,"
      print "      compute_config,"
      print "      storage_config,"
      print "      storage_config[0].block_storage,"
      print "      kubernetes_network_config,"
      print "      kubernetes_network_config[0].elastic_load_balancing"
      print "    ]"
      print "  }"
      inserted=1
    }
    if (depth_after==0) { print line; inres=0; depth=0; next }
    depth = depth_after; next
  }

  # Detect start of lifecycle block and skip it (we will re-insert canonical one later)
  if (match(line, /^[[:space:]]*lifecycle[[:space:]]*\{/)) {
    in_lc=1; lc_depth=1; next
  }

  # Handle depends_on array tracking when inside resource
  if (in_dep==1) {
    print line
    # Track square bracket depth for depends_on array
    for (i=1; i<=length(line); i++) { ch=substr(line,i,1); if (ch=="[") dep_depth++; else if (ch=="]") dep_depth-- }
    if (dep_depth<=0 && !inserted) {
      # Insert canonical lifecycle block immediately after depends_on array closes
      print "  lifecycle {"
      print "    ignore_changes = ["
      print "      access_config[0].bootstrap_cluster_creator_admin_permissions,"
      print "      bootstrap_self_managed_addons,"
      print "      compute_config,"
      print "      storage_config,"
      print "      storage_config[0].block_storage,"
      print "      kubernetes_network_config,"
      print "      kubernetes_network_config[0].elastic_load_balancing"
      print "    ]"
      print "  }"
      inserted=1; in_dep=0
    }
    # Resource end check on the same line
    if (depth_after==0 && !inserted) {
      print "  lifecycle {"
      print "    ignore_changes = ["
      print "      access_config[0].bootstrap_cluster_creator_admin_permissions,"
      print "      bootstrap_self_managed_addons,"
      print "      compute_config,"
      print "      storage_config,"
      print "      storage_config[0].block_storage,"
      print "      kubernetes_network_config,"
      print "      kubernetes_network_config[0].elastic_load_balancing"
      print "    ]"
      print "  }"
      inserted=1
    }
    if (depth_after==0) { print line; inres=0; depth=0; next }
    depth = depth_after; next
  }

  # If we see the start of depends_on array, print it and start tracking
  if (match(line, /^[[:space:]]*depends_on[[:space:]]*=/)) {
    print line
    # Initialize bracket depth if line already contains [ or ]
    dep_depth=0
    for (i=1; i<=length(line); i++) { ch=substr(line,i,1); if (ch=="[") dep_depth++; else if (ch=="]") dep_depth-- }
    in_dep=1
    # If depends_on starts and ends on the same line, inject right away
    if (dep_depth<=0 && !inserted) {
      print "  lifecycle {"
      print "    ignore_changes = ["
      print "      access_config[0].bootstrap_cluster_creator_admin_permissions,"
      print "      bootstrap_self_managed_addons,"
      print "      compute_config,"
      print "      storage_config,"
      print "      storage_config[0].block_storage,"
      print "      kubernetes_network_config,"
      print "      kubernetes_network_config[0].elastic_load_balancing"
      print "    ]"
      print "  }"
      inserted=1; in_dep=0
    }
    # Resource end check for same line
    if (depth_after==0 && !inserted) {
      print "  lifecycle {"
      print "    ignore_changes = ["
      print "      access_config[0].bootstrap_cluster_creator_admin_permissions,"
      print "      bootstrap_self_managed_addons,"
      print "      compute_config,"
      print "      storage_config,"
      print "      storage_config[0].block_storage,"
      print "      kubernetes_network_config,"
      print "      kubernetes_network_config[0].elastic_load_balancing"
      print "    ]"
      print "  }"
      inserted=1
    }
    if (depth_after==0) { print line; inres=0; depth=0; next }
    depth = depth_after; next
  }

  # Before closing resource: if this line closes the resource, inject lifecycle just before
  if (depth_after==0) {
    if (!inserted) {
      print "  lifecycle {"
      print "    ignore_changes = ["
      print "      access_config[0].bootstrap_cluster_creator_admin_permissions,"
      print "      bootstrap_self_managed_addons,"
      print "      compute_config,"
      print "      storage_config,"
      print "      storage_config[0].block_storage,"
      print "      kubernetes_network_config,"
      print "      kubernetes_network_config[0].elastic_load_balancing"
      print "    ]"
      print "  }"
      inserted=1
    }
    print line
    inres=0; depth=0; next
  }

  # Regular line inside resource
  print line
  depth = depth_after
}
AWK
#
# AWK: cleanup of stray standalone closing braces
cat > /tmp/clean_braces.awk <<'AWK'
BEGIN{ depth=0 }
{
  line=$0
  # If line is only a closing brace, decide based on current depth
  if (match(line, /^[[:space:]]*}[[:space:]]*$/)) {
    if (depth<=0) next
    print line
    depth--
    next
  }
  print line
  for (i=1;i<=length(line);i++) {
    c=substr(line,i,1)
    if (c=="{") depth++
    else if (c=="}") depth--
  }
}
END{
  if (depth!=0) {
    printf("WARN: brace depth ended at %d (expected 0)\n", depth) > "/dev/stderr"
  }
}
AWK
#
# Normalize + clean in one pass, write atomically
awk -f /tmp/normalize_eks_lifecycle.awk "$EKS_MAIN" \
  | awk -f /tmp/clean_braces.awk > "$EKS_MAIN.tmp" && mv "$EKS_MAIN.tmp" "$EKS_MAIN"

echo "✅ Lifecycle block normalized and cleaned in: $EKS_MAIN"

# Show the modified block for verification (robust)
awk '
  BEGIN{inres=0; depth=0}
  /resource[[:space:]]+"aws_eks_cluster"[[:space:]]+"this"[[:space:]]*\{/ {
    print "----- BEGIN patched aws_eks_cluster.this -----"; inres=1; depth=1; print; next
  }
  {
    if (inres==1) {
      print
      for (i=1;i<=length($0);i++){ c=substr($0,i,1); if(c=="{") depth++; else if(c=="}") depth--; }
      if (depth<=0) { print "----- END patched aws_eks_cluster.this -----"; inres=0 }
    }
  }
' "$EKS_MAIN" || true

# If nothing printed, show grep marker and head for context
if ! grep -n 'resource "aws_eks_cluster" "this"' "$EKS_MAIN"; then
  echo "(marker not found after patch) showing first 200 lines for context:"; sed -n '1,200p' "$EKS_MAIN"
fi
