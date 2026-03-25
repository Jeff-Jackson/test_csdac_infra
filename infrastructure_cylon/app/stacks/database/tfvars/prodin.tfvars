database_subnet_group        = "prodin-cylon" # Taken from AWS
database_security_group_id   = "sg-0fa9b701cf7804a1f" # Taken from AWS

mysql_instances = {
  primary = {
    instance_class         = "db.r6g.large"
    engine_version         = "8.4.6"
    monitoring_interval    = 60
    #  EXPLICITLY lock down the group families during the upgrade:
    family                 = "mysql8.4"
    major_engine_version   = "8.4"
    # Terraform will manage IAM role and policy attachment for Enhanced Monitoring
  }
}

mariadb_instances = {
  primary = {
    instance_class         = "db.r6g.2xlarge"
    monitoring_interval    = 60
    # Terraform will manage IAM role and policy attachment for Enhanced Monitoring
  }
}
