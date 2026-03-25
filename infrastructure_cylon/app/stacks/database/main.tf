locals {
  name       = "${var.env}-cylon"
  region     = var.region
  tags = {
    ResourceName = "${var.env}-cylon"
    Environment  = "cylon-${var.env}"
    Terraform    = "true"
    Env          = "cylon-${var.env}"
    map-migrated = "migAPKOFY9BS4"
  }
}

locals {
  # Ensure we always have at least one instance (primary) if tfvars omit instance maps
  effective_mariadb_instances = length(keys(var.mariadb_instances)) > 0 ? var.mariadb_instances : { primary = {} }
  effective_mysql_instances   = length(keys(var.mysql_instances))   > 0 ? var.mysql_instances   : { primary = {} }
}

# State move to keep the existing instance without recreation when switching to for_each
moved {
  from = module.mariadb
  to   = module.mariadb["primary"]
}

module "mariadb" {
  source  = "terraform-aws-modules/rds/aws"
  version = "6.9.0"

  for_each = local.effective_mariadb_instances

  engine               = "mariadb"
  engine_version       = coalesce(try(each.value.engine_version, null), var.mariadb_engine_version)
  instance_class = (try(trimspace(lookup(each.value, "instance_class", "")), "") != "") ? try(trimspace(lookup(each.value, "instance_class", "")), "") : var.mariadb_instance_class
  family               = coalesce(lookup(each.value, "family", null), var.mariadb_family)
  major_engine_version = coalesce(lookup(each.value, "major_engine_version", null), var.mariadb_major_engine_version)
  create_db_parameter_group = lookup(each.value, "create_db_parameter_group", true)
  create_db_option_group    = lookup(each.value, "create_db_option_group", true)
  identifier           = "${local.name}-mariadb${lookup(each.value, "suffix", null) == null ? "" : lookup(each.value, "suffix", "")}"

  allocated_storage     = lookup(each.value, "allocated_storage", var.mariadb_allocated_storage)
  max_allocated_storage = lookup(each.value, "max_allocated_storage", var.mariadb_max_allocated_storage)
  apply_immediately     = var.rds_apply_immediately
  allow_major_version_upgrade = true

  db_name  = "cylonMariaDB"
  username = "fireconsole"
  manage_master_user_password                       = true
  manage_master_user_password_rotation              = false
  master_user_password_rotate_immediately           = false
  master_user_password_rotation_schedule_expression = "rate(15 days)"
  port     = 3306

  multi_az               = false
  db_subnet_group_name   = var.database_subnet_group
  vpc_security_group_ids = [var.database_security_group_id]

  maintenance_window          = "Mon:00:00-Mon:03:00"
  backup_window               = "03:00-06:00"
  create_cloudwatch_log_group = false

  performance_insights_enabled          = false
  performance_insights_retention_period = 7
  create_monitoring_role = false
  monitoring_role_arn    = aws_iam_role.rds_monitoring.arn
  parameter_group_name = lookup(each.value, "parameter_group_name", null)
  option_group_name    = lookup(each.value, "option_group_name", null)
  monitoring_interval    = 60

  skip_final_snapshot = true
  deletion_protection = lookup(each.value, "deletion_protection", false)

  parameters = [
    {
      name  = "character_set_client"
      value = "utf8mb4"
    },
    {
      name  = "character_set_server"
      value = "utf8mb4"
    }
  ]

  tags = local.tags

  db_instance_tags = {
    "Sensitive" = "high"
  }
  db_option_group_tags = {
    "Sensitive" = "low"
  }
  db_parameter_group_tags = {
    "Sensitive" = "low"
  }
  db_subnet_group_tags = {
    "Sensitive" = "high"
  }
}

# State move to keep the existing MySQL instance when switching to for_each
moved {
  from = module.db
  to   = module.db["primary"]
}

module "db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "6.9.0"

  for_each = local.effective_mysql_instances

  identifier           = "${local.name}-mysql${lookup(each.value, "suffix", null) == null ? "" : lookup(each.value, "suffix", "")}"
  engine               = "mysql"
  engine_version       = coalesce(try(each.value.engine_version, null), var.mysql_engine_version)
  family               = coalesce(lookup(each.value, "family", null), var.mysql_family)
  major_engine_version = coalesce(lookup(each.value, "major_engine_version", null), var.mysql_major_engine_version)
  create_db_parameter_group = lookup(each.value, "create_db_parameter_group", true)
  create_db_option_group    = lookup(each.value, "create_db_option_group", true)
  instance_class = (try(trimspace(lookup(each.value, "instance_class", "")), "") != "") ? try(trimspace(lookup(each.value, "instance_class", "")), "") : var.mysql_instance_class
  allocated_storage     = var.mysql_allocated_storage
  max_allocated_storage = lookup(each.value, "max_allocated_storage", var.mysql_max_allocated_storage)
  apply_immediately     = var.rds_apply_immediately
  allow_major_version_upgrade = true

  db_name  = "cylonMysql"
  username = "fireconsole"
  manage_master_user_password                       = true
  manage_master_user_password_rotation              = false
  master_user_password_rotate_immediately           = false
  master_user_password_rotation_schedule_expression = "rate(15 days)"
  port     = 3306

  multi_az               = false
  db_subnet_group_name   = var.database_subnet_group
  vpc_security_group_ids = [var.database_security_group_id]

  maintenance_window          = "Mon:00:00-Mon:03:00"
  backup_window               = "03:00-06:00"
  create_cloudwatch_log_group = false

  performance_insights_enabled          = false
  performance_insights_retention_period = 7
  create_monitoring_role = false
  monitoring_role_arn    = aws_iam_role.rds_monitoring.arn
  parameter_group_name = lookup(each.value, "parameter_group_name", null)
  option_group_name    = lookup(each.value, "option_group_name", null)
  monitoring_interval    = 60


  skip_final_snapshot = true
  deletion_protection = lookup(each.value, "deletion_protection", false)

  parameters = [
    {
      name  = "character_set_client"
      value = "utf8mb4"
    },
    {
      name  = "character_set_server"
      value = "utf8mb4"
    }
  ]

  tags = local.tags

  db_instance_tags = {
    "Sensitive" = "high"
  }
  db_option_group_tags = {
    "Sensitive" = "low"
  }
  db_parameter_group_tags = {
    "Sensitive" = "low"
  }
  db_subnet_group_tags = {
    "Sensitive" = "high"
  }
}
