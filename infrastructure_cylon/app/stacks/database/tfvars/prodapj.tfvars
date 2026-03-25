database_subnet_group        = "prodapj-cylon" # Taken from AWS
database_security_group_id   = "sg-0fa1b10df7021030b" # Taken from AWS

# MySQL -> 8.4.6 + family 8.4 (without pin on old PG)
mysql_instances = {
  primary = {
    engine_version           = "8.4.6"
    family                   = "mysql8.4"
    major_engine_version     = "8.4"

    deletion_protection      = true
    monitoring_interval      = 60

    # IMPORTANT: Do not pin to old parameter group
    # parameter_group_name   = ""

    # Let the module create new PG/OG of the required family
    create_db_parameter_group = true
    create_db_option_group    = true
  }
}

# MariaDB -> 11.4.8 + family 11.4 (without pin on old PG)
mariadb_instances = {
  primary = {
    engine_version           = "11.4.8"
    family                   = "mariadb11.4"
    major_engine_version     = "11.4"

    deletion_protection      = true
    monitoring_interval      = 60

    # Do not pin to old parameter group
    # parameter_group_name   = ""

    create_db_parameter_group = true
    create_db_option_group    = true
  }
}
