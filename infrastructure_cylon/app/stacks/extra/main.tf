
### Policy for Velero to access from EC2 instances to AWS S3
resource "aws_iam_policy" "cylon_velero_policy" {
  name        = "<%= expansion('cylon-:ENV-velero-policy') %>"
  description = "Cylon EC2 Policy for Velero EKS Cluster"

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
                "arn:${var.arn_type}:s3:::velero-backup-<%= expansion('cylon-:ENV-cluster') %>/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:${var.arn_type}:s3:::velero-backup-<%= expansion('cylon-:ENV-cluster') %>"
            ]
        }
      ]
}
EOF
}

resource "aws_iam_policy" "cylon_cilium_policy" {
 count = var.arn_type == "aws-us-gov" ? 1 : 0
  name        = "<%= expansion('cylon-:ENV-cilium-policy') %>"
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

resource "aws_iam_policy" "node_efs_policy" {
  name        = "<%= expansion('cylon-:ENV-efs-node-policy') %>"
  path        = "/"
  description = "Policy for EFKS nodes to use EFS"

  policy = jsonencode({
    "Statement": [
        {
            "Action": [
                "elasticfilesystem:DescribeMountTargets",
                "elasticfilesystem:DescribeFileSystems",
                "elasticfilesystem:DescribeAccessPoints",
                "elasticfilesystem:CreateAccessPoint",
                "elasticfilesystem:DeleteAccessPoint",
                "ec2:DescribeAvailabilityZones"
            ],
            "Effect": "Allow",
            "Resource": "*",
            "Sid": ""
        }
    ],
    "Version": "2012-10-17"
}
  )
}
