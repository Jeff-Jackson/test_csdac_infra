### Policy for Vault to access from EC2 instances to AWS services
resource "aws_iam_policy" "csdac_vault_policy" {
  name        = "<%= expansion('csdac-:ENV-vault-policy') %>"
  description = "CSDAC EC2 Policy for Vault EKS Cluster"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "dynamodb:DescribeLimits",
          "dynamodb:DescribeTimeToLive",
          "dynamodb:ListTagsOfResource",
          "dynamodb:DescribeReservedCapacityOfferings",
          "dynamodb:DescribeReservedCapacity",
          "dynamodb:ListTables",
          "dynamodb:BatchGetItem",
          "dynamodb:BatchWriteItem",
          "dynamodb:CreateTable",
          "dynamodb:DeleteItem",
          "dynamodb:GetItem",
          "dynamodb:GetRecords",
          "dynamodb:PutItem",
          "dynamodb:Query",
          "dynamodb:UpdateItem",
          "dynamodb:Scan",
          "dynamodb:DescribeTable"
        ],
        "Resource": [ "arn:${var.arn_type}:dynamodb:<%= expansion(':REGION') %>:<%= expansion(':ACCOUNT') %>:table/vault-csdac-<%= expansion(':ENV') %>-cluster" ]
      },
      {
        "Effect": "Allow",
        "Action": [
          "kms:Get*",
          "kms:ListKeys",
          "kms:ListAliases",
          "kms:DescribeKey",
          "kms:Encrypt",
          "kms:Decrypt"
        ],
        "Resource": "*"
      }
      ]
}
EOF
}

### Policy for Velero to access from EC2 instances to AWS S3
resource "aws_iam_policy" "csdac_velero_policy" {
  name        = "<%= expansion('csdac-:ENV-velero-policy') %>"
  description = "CSDAC EC2 Policy for Velero EKS Cluster"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:DeleteObject",
                "s3:PutObject",
                "s3:AbortMultipartUpload",
                "s3:ListMultipartUploadParts"
            ],
            "Resource": [
                "arn:${var.arn_type}:s3:::velero-backup-<%= expansion('csdac-:ENV-cluster') %>/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:${var.arn_type}:s3:::velero-backup-<%= expansion('csdac-:ENV-cluster') %>"
            ]
        }
      ]
}
EOF
}

resource "aws_iam_policy" "csdac_cilium_policy" {
 count = var.arn_type == "aws-us-gov" ? 1 : 0
  name        = "<%= expansion('csdac-:ENV-cilium-policy') %>"
  description = "CSDAC EC2 Policy for cilium"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
         {
            "Action": [
               "ec2:CreateNetworkInterface",
               "ec2:DeleteNetworkInterface",
               "ec2:DescribeNetworkInterfaces",
               "ec2:AssignPrivateIpAddresses",
               "ec2:UnassignPrivateIpAddresses",
               "ec2:DescribeSubnets",
               "ec2:DescribeSecurityGroups",
               "ec2:CreateTags"
            ],
            "Effect": "Allow",
            "Resource": "*"
        }
      ]
}
EOF
}
