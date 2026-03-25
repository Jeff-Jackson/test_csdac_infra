provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}

locals {
  name        = "${var.env}-cylon"
  region      = var.region
  account_id  = data.aws_caller_identity.current.account_id
  cdo_account_id = can(regex("prod", var.env)) ? "005087805285" : "107042026245"
  # cdo_role = "arn:aws:iam::107042026245:role/ci-CRAT@ai-ops-bpr-ecs-task-role"
  cdo_role       = "arn:aws:iam::${local.cdo_account_id}:role/${var.env}-CRAT@ai-ops-bpr-ecs-task-role"

  tags = {
    Name        = local.name
    Environment = var.env
    Region      = var.region
  }
}

resource "aws_sqs_queue" "cylon_queue" {
  name                     = local.name
  sqs_managed_sse_enabled = false
  tags                    = local.tags
}

resource "aws_sqs_queue_policy" "sqs_policy" {
  queue_url = aws_sqs_queue.cylon_queue.id

  policy = jsonencode({
    Version = "2012-10-17",
    Id      = "__default_policy_ID",
    Statement = [
      {
        Sid       = "__owner_statement",
        Effect    = "Allow",
        Principal = {
          AWS = "arn:aws:iam::${local.account_id}:root"
        },
        Action   = "SQS:*",
        Resource = aws_sqs_queue.cylon_queue.arn
      },
      {
        Sid       = "AllowSendMessageFromCDOAccount",
        Effect    = "Allow",
        Principal = {
          AWS = "arn:aws:iam::${local.cdo_account_id}:root"
        },
        Condition = {
          StringEquals = {
            "aws:PrincipalArn" = local.cdo_role
          }
        },
        Action   = "SQS:SendMessage",
        Resource = aws_sqs_queue.cylon_queue.arn
      }
    ]
  })
}
