variable "cdo_account_id" {
  default = "107042026245"
}

variable "cdo_roles" {
  description = "List of roles of different environments in the CDO account"
  type        = list(string)
  default     = [
    "arn:aws:iam::${var.cdo_account_id}:role/staging-ai-ops-bpr-ecs-task-role",
    "arn:aws:iam::${var.cdo_account_id}:role/dev-ai-ops-bpr-ecs-task-role",
    "arn:aws:iam::${var.cdo_account_id}:role/qa-ai-ops-bpr-ecs-task-role"
  ]
}
 