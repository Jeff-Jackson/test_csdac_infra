database_subnet_group      = "staging-cylon" # Taken from AWS
database_security_group_id = "sg-0e307248a9a5020ea" # Taken from AWS

mariadb_instances = {
  primary = {
    instance_class    = "db.r6g.2xlarge"
    max_allocated_storage = 3000
  }
  secondary = {
    suffix            = "-secondary"
    instance_class    = "db.r6g.2xlarge"
    manage_master_user_password = true
    # allocated_storage = 1000
    # engine_version       = "10.11.8"
    # family               = "mariadb10.11"
    # major_engine_version = "10.11"
  }
}

mysql_instances = {
  primary = {
    instance_class = "db.r6g.large"
    engine_version         = "8.4.6"
    create_monitoring_role = false
    monitoring_role_arn    = "arn:aws:iam::012555280953:role/rds-monitoring-role"
  }
}
