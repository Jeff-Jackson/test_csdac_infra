database_subnet_group        = "prodaus-cylon" # Taken from AWS
database_security_group_id   = "sg-0f3442505bfb76e68" # Taken from AWS
mariadb_allocated_storage    = 520

# Stage 1: safe engine-only upgrade + deletion protection

mysql_instances = {
  primary = {
    # Engine-only upgrade (keep 8.0 families for step 1)
    engine_version         = "8.4.6"
    family                 = "mysql8.4"
    major_engine_version   = "8.4"

    # Safety
    deletion_protection    = true
    monitoring_interval    = 60
    parameter_group_name   = "prodaus-cylon-mysql-20241104150541873700000002"
    # Avoid unnecessary replacements during step 1:
    create_db_parameter_group = true
    create_db_option_group    = true
  }
}

mariadb_instances = {
  primary = {
    # Engine-only upgrade (keep 10.11 families for step 1)
    engine_version         = "11.4.8"
    family                 = "mariadb11.4"
    major_engine_version   = "11.4"

    # Safety
    deletion_protection    = true
    monitoring_interval    = 60
    parameter_group_name   = "prodaus-cylon-mariadb-20241104150541876500000004"
    # Avoid unnecessary replacements during step 1:
    create_db_parameter_group = true
    create_db_option_group    = true
  }
}
