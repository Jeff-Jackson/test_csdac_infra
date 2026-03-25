locals {
  account_id = "<%= expansion(':ACCOUNT') %>"

  # If var.cluster_admin_principals is empty, fall back to admin + devops
  effective_cluster_admin_principals = var.cluster_admin_principals

  # cluster creator (managed by module.eks) — must be excluded from our own Access Entries
  cluster_creator_arn = "arn:${var.arn_type}:iam::${local.account_id}:user/terraform"

  # --- Additional principals migrated from aws-auth ---
  base_admin_arns = [
    "arn:${var.arn_type}:iam::012555280953:role/service-role/Lambda-CDO-local-role-i4nv3byt",
    "arn:${var.arn_type}:iam::${local.account_id}:role/devops",
    "arn:${var.arn_type}:iam::${local.account_id}:role/admin",
    aws_iam_role.lambda_cdo_role.arn,
    aws_iam_role.lambda_cdo_remove_role.arn,
    aws_iam_role.eks_assume_role_policy.arn,
  ]

  commonservices_arns = [
    "arn:${var.arn_type}:iam::${local.account_id}:role/EKSCommonServiesTeamTrustRole",
  ]

  non_prod_devs_arns = can(regex("prod", var.cluster_name)) ? [] : [
    "arn:${var.arn_type}:iam::${local.account_id}:role/developers",
  ]
}

locals {
  # Filter out cluster creator and normalize access_entries to avoid duplicates with "admins"
  access_entries_filtered = {
    for name, cfg in var.access_entries :
    name => cfg
    if cfg.principal_arn != local.cluster_creator_arn
  }

  # Set of principals already covered by access_entries (after filtering)
  access_entries_principals = toset([for _, cfg in local.access_entries_filtered : cfg.principal_arn])
}

# aws_eks_access_entry for each principal
resource "aws_eks_access_entry" "admins" {
  for_each = length(local.effective_cluster_admin_principals) > 0 ? setsubtract(
    toset(local.effective_cluster_admin_principals),
    setunion(toset([local.cluster_creator_arn]), local.access_entries_principals)
  ) : toset([])
  cluster_name      = module.eks.cluster_name
  principal_arn     = each.value
  tags              = local.tags
}

# policy association (cluster-admin policy) for each entry
resource "aws_eks_access_policy_association" "admins_policy" {
  for_each     = aws_eks_access_entry.admins
  cluster_name  = module.eks.cluster_name

  # According to AWS specifications, this policy has the following ARN
  policy_arn    = var.cluster_admin_policy_arn
  principal_arn = each.value.principal_arn
  access_scope { type = "cluster" }
}

#####################################################################
# Generic Access Entries driven by var.access_entries (e.g., CDO)
#####################################################################

# Flatten policy associations for_each consumption
locals {
  access_entries_assoc_flat = {
    for obj in flatten([
      for name, cfg in local.access_entries_filtered : [
        for idx, pa in cfg.policy_associations : {
          key           = "${name}#${idx}"
          principal_arn = cfg.principal_arn
          policy_arn    = pa.policy_arn
          access_scope  = pa.access_scope
        }
      ]
    ]) : obj.key => obj
  }
}

# Create an access entry per item in var.access_entries
resource "aws_eks_access_entry" "this" {
  for_each      = local.access_entries_filtered
  cluster_name  = module.eks.cluster_name
  principal_arn = each.value.principal_arn
  type          = "STANDARD"
  tags          = local.tags
}

# Associate policies for each access entry policy_associations
resource "aws_eks_access_policy_association" "custom" {
  for_each      = local.access_entries_assoc_flat
  cluster_name  = module.eks.cluster_name
  principal_arn = each.value.principal_arn
  policy_arn    = each.value.policy_arn

  dynamic "access_scope" {
    for_each = [each.value.access_scope]
    content {
      type       = try(access_scope.value.type, "cluster")
      namespaces = try(access_scope.value.namespaces, null)
    }
  }
}
