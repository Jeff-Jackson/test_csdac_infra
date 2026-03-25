output "sqs_queue_arn" {
  description = "ARN of the SQS queue"
  value       = aws_sqs_queue.cylon_queue.arn
}

output "sqs_queue_url" {
  description = "URL of the SQS queue"
  value       = aws_sqs_queue.cylon_queue.id
}

output "sqs_policy_arn" {
  value = aws_iam_policy.cylon_sqs_policy.arn
}
