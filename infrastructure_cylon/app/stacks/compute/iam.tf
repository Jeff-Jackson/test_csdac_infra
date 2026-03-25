resource "aws_iam_policy" "datadog_policy" {
  name        = "${local.name}-datadog"
  description = "Cylon policy with datadoog required access"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "Statement1",
        Effect = "Allow",
        Action = [
          "ec2:DescribeInstanceStatus",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeInstances",
          "ec2:DescribeTags"
        ],
        Resource = ["*"]
      }
    ]
  })
}

resource "aws_iam_policy" "ecr_pull_policy" {
  name        = "${local.name}-ecr-ro"
  description = "Cylon policy to pull images"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ecr:GetAuthorizationToken"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetRepositoryPolicy",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages",
          "ecr:BatchGetImage",
          "ecr:GetLifecyclePolicy",
          "ecr:GetLifecyclePolicyPreview",
          "ecr:ListTagsForResource",
          "ecr:DescribeImageScanFindings"
        ],
        Resource = [
          "arn:aws:ecr:us-east-2:012555280953:repository/fireconsole-webui",
          "arn:aws:ecr:us-east-2:012555280953:repository/fireconsole-redis",
          "arn:aws:ecr:us-east-2:012555280953:repository/fireconsole_supervisor_dockerfile"
        ]
      }
    ]
  })
}

# 🔒 Reuse existing policies passed via tfvars
# resource "aws_iam_role_policy_attachment" "attach_datadog" {
#   role       = data.aws_iam_role.cylon.name
#   policy_arn = var.datadog_policy_arn
# }
#
# resource "aws_iam_role_policy_attachment" "attach_ecr" {
#   role       = data.aws_iam_role.cylon.name
#   policy_arn = var.ecr_pull_policy_arn
# }
#
# resource "aws_iam_role_policy_attachment" "attach_rds" {
#   role       = data.aws_iam_role.cylon.name
#   policy_arn = var.rds_read_policy_arn
# }
#
# resource "aws_iam_role_policy_attachment" "attach_sqs" {
#   role       = data.aws_iam_role.cylon.name
#   policy_arn = var.sqs_policy_arn
# }

resource "aws_iam_role" "cylon" {
  name = "${local.name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Effect = "Allow",
        Sid    = ""
      }
    ]
  })
}

resource "aws_iam_instance_profile" "cylon" {
  count = var.create_instance_profile ? 1 : 0
  name  = local.name
  role  = aws_iam_role.cylon.name
}

data "aws_iam_instance_profile" "cylon_existing" {
  count = var.create_instance_profile ? 0 : 1
  name  = local.name
}

locals {
  # Prefer the created instance profile if present, otherwise fall back to the existing one
  iam_instance_profile_name = one(
    concat(
      aws_iam_instance_profile.cylon[*].name,
      data.aws_iam_instance_profile.cylon_existing[*].name,
    )
  )
}

# resource "aws_iam_role_policy_attachment" "attach_ecr" {
#   role       = aws_iam_role.cylon.name
#   policy_arn = aws_iam_policy.ecr_pull_policy.arn
# }

resource "aws_iam_role_policy_attachment" "attach_ecr" {
  role       = aws_iam_role.cylon.name
  policy_arn = aws_iam_policy.ecr_pull_policy.arn
}

resource "aws_iam_role_policy_attachment" "attach_datadog" {
  role       = aws_iam_role.cylon.name
  policy_arn = aws_iam_policy.datadog_policy.arn
}

resource "aws_iam_role_policy_attachment" "attach_rds" {
  role       = aws_iam_role.cylon.name
  policy_arn = var.rds_read_policy_arn
}

resource "aws_iam_role_policy_attachment" "attach_sqs" {
  role       = aws_iam_role.cylon.name
  policy_arn = var.sqs_policy_arn
}
