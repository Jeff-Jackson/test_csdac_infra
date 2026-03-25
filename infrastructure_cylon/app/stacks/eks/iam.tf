resource "aws_iam_role" "eks_cylon_assume_role_policy" {
  name = "<%= expansion('cylon-:ENV-cluster-role') %>"
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "AWS": "arn:${var.arn_type}:iam::<%= expansion(':ACCOUNT') %>:root"
        },
        "Action": "sts:AssumeRole",
        "Condition": {}
      }
    ]
  })
}

resource "aws_iam_policy" "cylon_eks_policy" {
  name        = "<%= expansion('cylon-:ENV-cluster-eks-policy') %>"
  description = "Cylon EKS Policy for Role Cluster"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "NavigateInConsole",
            "Effect": "Allow",
            "Action": [
                "iam:GetGroupPolicy",
                "iam:GetPolicyVersion",
                "iam:GetPolicy",
                "iam:ListAttachedGroupPolicies",
                "iam:ListGroupPolicies",
                "iam:ListPolicyVersions",
                "iam:ListPolicies",
                "iam:ListUsers"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "eks:*"
            ],
            "Resource": "arn:${var.arn_type}:eks:${var.region}:<%= expansion(':ACCOUNT') %>:cluster/cylon-<%= expansion(':ENV') %>-cluster"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "attach_eks_policy_to_role" {
  role       = aws_iam_role.eks_cylon_assume_role_policy.name
  policy_arn = aws_iam_policy.cylon_eks_policy.arn
}
