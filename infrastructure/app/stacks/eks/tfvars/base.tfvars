vpc_id = <%= output("vpc.vpc_id") %>
cluster_version = "1.32"
eks_ami = "1.32.9-20251120"
eks_ami_type = "AL2_x86_64"
user_data = false
arn_type = "aws"
private_subnets = <%= output("vpc.private_subnets", mock: ["10.220.0.0/20", "10.220.16.0/20", "10.220.32.0/20"]) %>
eks_instance_type = "m4.xlarge"
eks_capacity_type = "SPOT"
eks_node_desired = 3
eks_node_max = 10
eks_node_min = 3
csdac_vault_policy_arn = <%= output("extra.csdac_vault_policy_arn", mock: "aws.mock.arn") %>
csdac_velero_policy_arn = <%= output("extra.csdac_velero_policy_arn", mock: "aws.mock.arn") %>
csdac_s3_decrypt_policy = <%= output("extra.csdac_s3_decrypt_policy", mock: "aws.mock.arn") %>
csdac_cilium_policy = <%= output("extra.csdac_cilium_policy", mock: "aws.mock.arn") %>
manage_aws_auth_configmap = false
# Optional: override cluster admin principals.
# Leave empty to use the default admin role from local.account_id
cluster_admin_principals = []
