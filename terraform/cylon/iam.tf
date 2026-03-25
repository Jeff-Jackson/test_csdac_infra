resource "aws_iam_policy" "cylon-db-ro-policy" {
  name        = "${local.name}-db-ro-secrets"
  description = "Cylon policy to get rds secrets"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "secretsmanager:GetResourcePolicy",
                "secretsmanager:GetSecretValue",
                "secretsmanager:DescribeSecret",
                "secretsmanager:ListSecretVersionIds"
            ],
            "Resource": [
              "${module.db.db_instance_master_user_secret_arn}",              
              "${module.mariadb.db_instance_master_user_secret_arn}"
            ]
        },
        {
            "Effect": "Allow",
            "Action": "secretsmanager:ListSecrets",
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_policy" "cylon-datadog-policy" {
  name        = "${local.name}-datadog"
  description = "Cylon policy with datadoog required access"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Statement1",
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeInstanceStatus",
                "ec2:DescribeSecurityGroups",
                "ec2:DescribeInstances",
                "ec2:DescribeTags"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_policy" "ecr-pull-policy" {
  name        = "${local.name}-ecr-ro"
  description = "Cylon policy to pull images"

  policy = <<EOF
  {
      "Version": "2012-10-17",
      "Statement": [
          {
              "Effect": "Allow",
              "Action": [
                  "ecr:GetAuthorizationToken"
              ],
              "Resource": "*"
          },
          {
              "Effect": "Allow",
              "Action": [
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
              "Resource": [
                  "arn:aws:ecr:us-east-2:012555280953:repository/fireconsole-webui",
                  "arn:aws:ecr:us-east-2:012555280953:repository/fireconsole-redis",
                  "arn:aws:ecr:us-east-2:012555280953:repository/fireconsole_supervisor_dockerfile"
              ]
          }
      ]
  }
EOF
}

resource "aws_iam_policy" "cylon-sqs-policy" {
  name        = "${local.name}-sqs-secrets"
  description = "Cylon policy to get sqs data"

  policy = <<EOF
  {
      "Version": "2012-10-17",
      "Statement": [
          {
              "Sid": "Statement1",
              "Effect": "Allow",
              "Action": [
                  "sqs:ReceiveMessage",
                  "sqs:DeleteMessage"
              ],
              "Resource": [
                  "${aws_sqs_queue.cylon_queue.arn}"
              ]
          }
      ]
  }
EOF
}

resource "aws_iam_role" "cylon" {
  name = local.name

  assume_role_policy = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "ec2.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
  }
EOF
}
resource "aws_iam_instance_profile" "instance_profile" {
  name = local.name
  role = aws_iam_role.cylon.name
}
resource "aws_iam_role_policy_attachment" "attach-rds" {
  role       = aws_iam_role.cylon.name
  policy_arn = aws_iam_policy.cylon-db-ro-policy.arn
}
resource "aws_iam_role_policy_attachment" "attach-ecr" {
  role       = aws_iam_role.cylon.name
  policy_arn = aws_iam_policy.ecr-pull-policy.arn
}
resource "aws_iam_role_policy_attachment" "attach-sqs" {
  role       = aws_iam_role.cylon.name
  policy_arn = aws_iam_policy.cylon-sqs-policy.arn
}
resource "aws_iam_role_policy_attachment" "attach-dd" {
  role       = aws_iam_role.cylon.name
  policy_arn = aws_iam_policy.cylon-datadog-policy.arn
}
