resource "aws_sqs_queue" "cylon_queue" {
  name                    = local.name
  sqs_managed_sse_enabled = false
  tags = {
    Name        = local.name
    Environment = var.env
    Region      = local.region
  }
}


resource "aws_sqs_queue_policy" "sqs-policy" {
  queue_url = aws_sqs_queue.cylon_queue.id
  policy    = <<EOF
  {
    "Version": "2012-10-17",
    "Id": "__default_policy_ID",
    "Statement": [
      {
        "Sid": "__owner_statement",
        "Effect": "Allow",
        "Principal": {
          "AWS": "arn:aws:iam::${local.account_id}:root"
        },
        "Action": "SQS:*",
        "Resource": "${aws_sqs_queue.cylon_queue.arn}"
      },
      {
        "Sid": "AllowSendMessageFromCDOAccount",
        "Effect": "Allow",
        "Principal": {
            "AWS": "${local.cdo_role}"
        },
        "Action": "SQS:SendMessage",
        "Resource": "${aws_sqs_queue.cylon_queue.arn}"
      }
    ]
  }
  EOF
}
