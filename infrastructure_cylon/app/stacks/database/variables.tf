variable "region" {
  type        = string
  description = "AWS Region"
}

variable "env" {
  description = "Environment type (ci, dev, staging, prod)"
  type        = string
}

variable "database_subnet_group" {
  description = "Database subnet group name"
  type        = string
}

variable "database_security_group_id" {
  description = "Database security group ID"
  type        = string
}

variable "mariadb_allocated_storage" {
  description = "Initial allocated storage for MariaDB"
  type        = number
  default     = 1000
}

variable "mysql_allocated_storage" {
  description = "Initial allocated storage for MySQL"
  type        = number
  default     = 100
}

variable "mariadb_instances" {
  description = "Set of MariaDB instances to create (use map keys as stable identifiers)."
  type = map(object({
    suffix                      = optional(string)
    instance_class              = optional(string)
    allocated_storage           = optional(number)
    engine_version              = optional(string)
    family                      = optional(string)
    major_engine_version        = optional(string)
    manage_master_user_password = optional(bool)
  }))
  default = {
    primary = {}
  }
}

variable "mysql_instances" {
  description = "Map of MySQL instances (primary + optional others)"
  type = map(object({
    suffix               = optional(string)
    instance_class       = optional(string)
    allocated_storage    = optional(number)
    engine_version       = optional(string)
    family               = optional(string)
    major_engine_version = optional(string)
  }))
  default = {
    primary = {} # By default, we create one primary
  }
}

variable "mariadb_engine_version" {
  description = "Target MariaDB engine version (e.g., 11.4.8)."
  type        = string
  default     = "11.4.8"
  validation {
    condition     = can(regex("^11\\.(4|8)\\.\\d+$", var.mariadb_engine_version))
    error_message = "mariadb_engine_version must be 11.4.x or 11.8.x (e.g., 11.4.8 or 11.8.2)."
  }
}

variable "mariadb_instance_class" {
  description = "Instance class for the MariaDB RDS instance (e.g., db.r6g.xlarge, db.r7g.2xlarge). Used to adjust CPU/RAM per region or environment."
  type        = string
  default     = "db.r6g.xlarge"
}

variable "mariadb_family" {
  description = "DB parameter group family for MariaDB (e.g., mariadb10.11, mariadb11.4, mariadb11.8)."
  type        = string
  default     = "mariadb11.4"
}

variable "mariadb_major_engine_version" {
  description = "Major engine version string for MariaDB option group (e.g., 10.11, 11.4, 11.8)."
  type        = string
  default     = "11.4"
}

variable "mysql_instance_class" {
  description = "Instance class for the MySQL RDS instance (e.g., db.r6g.large, db.r7g.2xlarge). Used to adjust CPU/RAM per region or environment."
  type        = string
  default     = "db.r6g.large"
}

variable "mariadb_max_allocated_storage" {
  description = "Max allocated storage for MariaDB"
  type        = number
  default     = 3000
}

variable "mysql_engine_version" {
  description = "Target MySQL engine version (supports in-place 8.0.x → 8.4.x on RDS). Example: 8.4.6"
  type        = string
  default     = "8.4.6"
  validation {
    condition     = can(regex("^8\\.4\\.\\d+$", var.mysql_engine_version))
    error_message = "mysql_engine_version must be 8.4.x (e.g., 8.4.6)."
  }
}

variable "mysql_family" {
  description = "DB parameter group family for MySQL (e.g., mysql8.0 or mysql8.4)."
  type        = string
  default     = "mysql8.4"
}

variable "mysql_major_engine_version" {
  description = "Major engine version string for MySQL option group (e.g., 8.0 or 8.4)."
  type        = string
  default     = "8.4"
}

variable "mysql_max_allocated_storage" {
  description = "Max allocated storage for MySQL"
  type        = number
  default     = 2000
}

variable "rds_apply_immediately" {
  description = "Whether to apply RDS changes immediately (causes short downtime if true). Usually set to false in production."
  type        = bool
  default     = false
}
