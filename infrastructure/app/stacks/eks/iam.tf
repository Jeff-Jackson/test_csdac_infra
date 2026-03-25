locals {
  cdo_role_name = "<%= expansion('Lambda-CDO-:ENV') %>"
  cdo_role_remove_name = "<%= expansion('Lambda-CDO-remove-:ENV') %>"
}

resource "aws_iam_role" "eks_assume_role_policy" {
  name = "<%= expansion('csdac-:ENV-cluster-role') %>"
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

resource "aws_iam_policy" "csdac_eks_policy" {
  name        = "<%= expansion('csdac-:ENV-cluster-eks-policy') %>"
  description = "CSDAC EKS Policy for Role Cluster"

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
            "Resource": "arn:${var.arn_type}:eks:${var.region}:<%= expansion(':ACCOUNT') %>:cluster/csdac-<%= expansion(':ENV') %>-cluster"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "attach_eks_policy_to_role" {
  role       = aws_iam_role.eks_assume_role_policy.name
  policy_arn = aws_iam_policy.csdac_eks_policy.arn
}

### CDO Role
resource "aws_iam_role" "lambda_cdo_role" {
  name = "${local.cdo_role_name}-role"
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "lambda.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      },
      {
        "Effect": "Allow",
        "Principal": {
          AWS = concat(
            [
              "arn:${var.arn_type}:iam::<%= expansion(':ACCOUNT') %>:root"
            ],
            var.arn_type == "aws-us-gov" ? [
              "arn:aws-us-gov:iam::202850378426:root"
            ] : [
              "arn:aws:iam::107042026245:root",
              "arn:aws:iam::005087805285:root"
            ]
          )
        },
        "Action": "sts:AssumeRole",
        "Condition": {}
      }
    ]
  })
}


resource "aws_iam_policy" "lambda_cdo_policy" {
  name        = "${local.cdo_role_name}-policy"
  description = "Lambda CDO Policy for Role Env: <%= expansion(':ENV') %>"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeInstances",
                "iam:GetInstanceProfile",
                "iam:GetUser",
                "iam:GetRole"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "sts:AssumeRole"
            ],
            "Resource": [
                "arn:${var.arn_type}:iam::*:role/*"
            ]
        },
        {
            "Sid": "ManageOwnAccessKeys",
            "Effect": "Allow",
            "Action": [
                "iam:CreateAccessKey",
                "iam:DeleteAccessKey",
                "iam:GetAccessKeyLastUsed",
                "iam:GetUser",
                "iam:ListAccessKeys",
                "iam:UpdateAccessKey"
            ],
            "Resource": "arn:${var.arn_type}:iam::*:user/*"
        },
        {
            "Sid": "STSLambdaCDO",
            "Effect": "Allow",
            "Action": [
                "eks:DescribeCluster",
                "eks:ListClusters"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "logs:CreateLogGroup",
            "Resource": "arn:${var.arn_type}:logs:*:<%= expansion(':ACCOUNT') %>:*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": [
                "arn:${var.arn_type}:logs:*:<%= expansion(':ACCOUNT') %>:log-group:/aws/lambda/Lambda-CDO-<%= expansion(':ENV') %>-role:*"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "attach_cdo_policy_to_role" {
  role       = aws_iam_role.lambda_cdo_role.name
  policy_arn = aws_iam_policy.lambda_cdo_policy.arn
}


### CDO Remove Lambda Role
resource "aws_iam_role" "lambda_cdo_remove_role" {
  name = "${local.cdo_role_remove_name}-role"
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "lambda.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      },
      {
        "Effect": "Allow",
        "Principal": {
          AWS = concat (
            [
              "arn:${var.arn_type}:iam::<%= expansion(':ACCOUNT') %>:root"
            ],
            var.arn_type == "aws-us-gov" ? [
              "arn:aws-us-gov:iam::202850378426:root"
            ] : [
              "arn:aws:iam::107042026245:root",
              "arn:aws:iam::005087805285:root"
            ]
          )
        },
        "Action": "sts:AssumeRole",
        "Condition": {}
      }
    ]
  })
}


resource "aws_iam_policy" "lambda_cdo_remove_policy" {
  name        = "${local.cdo_role_remove_name}-policy"
  description = "Lambda CDO Policy for Role Remove Env: <%= expansion(':ENV') %>"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeInstances",
                "iam:GetInstanceProfile",
                "iam:GetUser",
                "iam:GetRole"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "sts:AssumeRole"
            ],
            "Resource": [
                "arn:${var.arn_type}:iam::*:role/*"
            ]
        },
        {
            "Sid": "ManageOwnAccessKeys",
            "Effect": "Allow",
            "Action": [
                "iam:CreateAccessKey",
                "iam:DeleteAccessKey",
                "iam:GetAccessKeyLastUsed",
                "iam:GetUser",
                "iam:ListAccessKeys",
                "iam:UpdateAccessKey"
            ],
            "Resource": "arn:${var.arn_type}:iam::*:user/*"
        },
        {
            "Sid": "STSLambdaCDO",
            "Effect": "Allow",
            "Action": [
                "eks:DescribeCluster",
                "eks:ListClusters"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "logs:CreateLogGroup",
            "Resource": "arn:${var.arn_type}:logs:*:<%= expansion(':ACCOUNT') %>:*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": [
                "arn:${var.arn_type}:logs:*:<%= expansion(':ACCOUNT') %>:log-group:/aws/lambda/Lambda-CDO-remove-<%= expansion(':ENV') %>-role:*"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "attach_cdo_remove_policy_to_role" {
  role       = aws_iam_role.lambda_cdo_remove_role.name
  policy_arn = aws_iam_policy.lambda_cdo_remove_policy.arn
}
