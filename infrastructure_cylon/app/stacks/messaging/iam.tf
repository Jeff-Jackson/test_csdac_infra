resource "aws_iam_policy" "cylon_sqs_policy" {
  name        = "${local.name}-sqs-secrets"
  description = "Cylon policy to access SQS queue"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "Statement1",
        Effect = "Allow",
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ],
        Resource = [aws_sqs_queue.cylon_queue.arn]
      }
    ]
  })
}
