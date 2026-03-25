data "aws_sqs_queue" "cylon_aas_queue" {
  name = "cylon-aas"
}

resource "aws_sqs_queue_policy" "cylon_aas_queue_policy" {
  queue_url = data.aws_sqs_queue.cylon_aas_queue.url

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        AWS = "arn:aws:iam::${var.cdo_account_id}:role/staging-ai-ops-bpr-ecs-task-role"
      },
      Action = "sqs:SendMessage",
      Resource = data.aws_sqs_queue.cylon_aas_queue.arn
    }]
  })
} 
