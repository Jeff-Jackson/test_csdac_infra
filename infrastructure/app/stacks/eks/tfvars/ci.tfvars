eks_node_min     = 1
eks_node_desired = 1
eks_node_max     = 1

# Access entries (API mode). Explicit mapping replaces cluster_admin_principals
cluster_admin_principals = []

access_entries = {
    admin = {
      principal_arn = "arn:aws:iam::012555280953:role/admin"
      policy_associations = [{
        policy_arn  = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
        access_scope = { type = "cluster" }
      }]
    }
  devops = {
    principal_arn = "arn:aws:iam::012555280953:role/devops"
    policy_associations = [{
      policy_arn  = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
      access_scope = { type = "cluster" }
    }]
  }
  developers = {
    principal_arn = "arn:aws:iam::012555280953:role/developers"
    policy_associations = [{
      policy_arn  = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
      access_scope = { type = "cluster" }
    }]
  }
  commonservices = {
    principal_arn = "arn:aws:iam::012555280953:role/EKSCommonServiesTeamTrustRole"
    policy_associations = [{
      policy_arn  = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"
      access_scope = { type = "cluster" }
    }]
  }
  lambda_local = {
    principal_arn = "arn:aws:iam::012555280953:role/service-role/Lambda-CDO-local-role-i4nv3byt"
    policy_associations = [{
      policy_arn  = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
      access_scope = { type = "cluster" }
    }]
  }
  lambda_ci = {
    principal_arn = "arn:aws:iam::012555280953:role/Lambda-CDO-ci-role"
    policy_associations = [{
      policy_arn  = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
      access_scope = { type = "cluster" }
    }]
  }
  lambda_remove_ci = {
    principal_arn = "arn:aws:iam::012555280953:role/Lambda-CDO-remove-ci-role"
    policy_associations = [{
      policy_arn  = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
      access_scope = { type = "cluster" }
    }]
  }
  csdac_ci_cluster = {
    principal_arn = "arn:aws:iam::012555280953:role/csdac-ci-cluster-role"
    policy_associations = [{
      policy_arn  = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
      access_scope = { type = "cluster" }
    }]
  }
}

# Explicitly assign the required managed policies to the cluster role.
cluster_iam_role_additional_policies = [
  "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
  "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController",
]

# Featured flags for access
enable_base_admins    = false
enable_commonservices = false
enable_non_prod_devs  = false

# Avoiding no-op updates EKS Auto Mode
cluster_compute_config            = null
cluster_storage_config            = null
cluster_kubernetes_network_config = null

manage_cluster_security_group_rules = true
manage_node_security_group_rules    = true

create_cluster_security_group = false
create_node_security_group    = false

cluster_security_group_id = "sg-02650784920f9873a"
node_security_group_id    = "sg-05a2f9147f92f8581"
