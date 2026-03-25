output "db_instance_address" {
  description = "The address of the RDS instance"
  value       = module.db.db_instance_address
}

output "db_instance_arn" {
  description = "The ARN of the RDS instance"
  value       = module.db.db_instance_arn
}

output "db_instance_identifier" {
  description = "The RDS instance identifier"
  value       = module.db.db_instance_identifier
}

output "db_instance_endpoint" {
  description = "The connection endpoint"
  value       = module.db.db_instance_endpoint
}

output "db_instance_port" {
  description = "The database port"
  value       = module.db.db_instance_port
}

output "db_instance_engine" {
  description = "The database engine"
  value       = module.db.db_instance_engine
}

output "db_instance_engine_version_actual" {
  description = "The running version of the database"
  value       = module.db.db_instance_engine_version_actual
}

output "db_instance_username" {
  description = "The master username for the database"
  value       = module.db.db_instance_username
  sensitive   = true
}
output "db_instance_master_user_secret_arn" {
  description = "MySQL The ARN of the master user secret"
  value       = module.db.db_instance_master_user_secret_arn
}

output "mariadb_instance_master_user_secret_arn" {
  description = "MariaDB The ARN of the master user secret"
  value       = module.mariadb.db_instance_master_user_secret_arn
}
output "mariadb_instance_endpoint" {
  description = "MariaDB The connection endpoint"
  value       = module.mariadb.db_instance_endpoint
}
output "private_key" {
  value = tls_private_key.ssh_key.private_key_pem
  sensitive = true
}
