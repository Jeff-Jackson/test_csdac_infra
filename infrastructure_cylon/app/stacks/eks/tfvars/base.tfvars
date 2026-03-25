vpc_id = <%= output("vpc.vpc_id") %>
cluster_version = "1.32"
eks_ami = "1.32.0-20250123"
eks_ami_type = "AL2_x86_64"
user_data = false
arn_type = "aws"
private_subnets = <%= output("vpc.private_subnets", mock: ["10.221.0.0/20", "10.221.16.0/20", "10.221.32.0/20"]) %>
eks_instance_type = "m5.xlarge"
eks_capacity_type = "SPOT"
eks_node_desired = "3"
eks_node_max = "5"
eks_node_min = "3"
cylon_velero_policy_arn = <%= output("extra.cylon_velero_policy_arn", mock: "aws.mock.arn") %>
csdac_cilium_policy = <%= output("extra.cylon_cilium_policy", mock: "aws.mock.arn") %>
cylon_node_efs_policy_arn = <%= output("extra.cylon_node_efs_policy", mock: "aws.mock.arn") %>
