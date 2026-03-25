module "mariadb" {
  source  = "terraform-aws-modules/rds/aws"
  version = "6.9.0"

  engine               = "mariadb"
  engine_version       = "10.11.8"
  instance_class       = "db.r6g.xlarge"
  family               = "mariadb10.11" # DB parameter group
  major_engine_version = "10.11"
  identifier           = "${local.name}-mariadb"

  allocated_storage     = 100
  max_allocated_storage = 1000

  db_name  = "cylonMariaDB"
  username = "fireconsole"
  manage_master_user_password                       = true
  manage_master_user_password_rotation              = false
  master_user_password_rotate_immediately           = false
  master_user_password_rotation_schedule_expression = "rate(15 days)"
  port     = 3306

  multi_az               = false
  db_subnet_group_name   = module.vpc.database_subnet_group
  vpc_security_group_ids = [module.security_group.security_group_id]


  maintenance_window          = "Mon:00:00-Mon:03:00"
  backup_window               = "03:00-06:00"
  create_cloudwatch_log_group = false


  performance_insights_enabled          = false
  performance_insights_retention_period = 7
  create_monitoring_role                = false
  monitoring_interval                   = 0


  skip_final_snapshot = true
  deletion_protection = false

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
