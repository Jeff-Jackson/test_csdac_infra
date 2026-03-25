# -----------------------------------------------------------------------------
# NOTE ABOUT ENGINE VERSIONS IN OUTPUTS
# -----------------------------------------------------------------------------
# We intentionally DO NOT export *engine version* values from Terraform outputs.
# During in-place upgrades the state/outputs can briefly be stale and misleading.
# The canonical, up-to-date engine versions are printed in the Jenkins stage
# "Post-Apply Refresh & Outputs" after a state refresh.
# -----------------------------------------------------------------------------

output "db_instance_address" {
  description = "The address of the RDS instance"
  value       = module.db["primary"].db_instance_address
}

output "db_instance_arn" {
  description = "The ARN of the RDS instance"
  value       = module.db["primary"].db_instance_arn
}

output "db_instance_identifier" {
  description = "The RDS instance identifier"
  value       = module.db["primary"].db_instance_identifier
}

output "db_instance_endpoint" {
  description = "The connection endpoint"
  value       = module.db["primary"].db_instance_endpoint
}

output "db_instance_port" {
  description = "The database port"
  value       = module.db["primary"].db_instance_port
}

output "db_instance_engine" {
  description = "The database engine"
  value       = module.db["primary"].db_instance_engine
}

output "db_instance_username" {
  description = "The master username for the database"
  value       = module.db["primary"].db_instance_username
  sensitive   = true
}

output "db_instance_master_user_secret_arn" {
  description = "MySQL master user secret ARN (primary)"
  value       = module.db["primary"].db_instance_master_user_secret_arn
}

# MySQL: ARN of secrets for all instances (per key)
output "mysql_instance_master_user_secret_arns" {
  description = "MySQL master user secret ARNs per instance key (nullable)"
  value       = { for k, m in module.db : k => try(m.db_instance_master_user_secret_arn, null) }
}

# MySQL: endpoints for all instances
output "mysql_instance_endpoints" {
  description = "MySQL endpoints per instance key"
  value       = { for k, m in module.db : k => m.db_instance_endpoint }
}

# Convenience: primary MySQL endpoint (kept for backwards compatibility)
output "mysql_primary_endpoint" {
  description = "Primary MySQL endpoint"
  value       = module.db["primary"].db_instance_endpoint
}

# MariaDB: ARN of secrets (may be null if Secrets Manager is not used)
output "mariadb_instance_master_user_secret_arns" {
  description = "MariaDB master user secret ARNs per instance key (nullable)"
  value       = { for k, m in module.mariadb : k => try(m.db_instance_master_user_secret_arn, null) }
}

# MariaDB: endpoints for all instances
output "mariadb_instance_endpoints" {
  description = "MariaDB endpoints per instance key"
  value       = { for k, m in module.mariadb : k => m.db_instance_endpoint }
}

output "rds_read_policy_arn" {
  description = "IAM policy ARN to read secrets from MariaDB and MySQL"
  value       = aws_iam_policy.cylon_db_ro_policy.arn
}

output "db_read_secrets_policy_arn" {
  value = aws_iam_policy.cylon_db_ro_policy.arn
}

output "mariadb_primary_endpoint" {
  description = "Primary MariaDB endpoint"
  value       = module.mariadb["primary"].db_instance_endpoint
}
