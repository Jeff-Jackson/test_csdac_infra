database_subnet_group      = <%= output('vpc.db_subnet_group') %>
database_security_group_id = <%= output('vpc.security_group_id') %>
mariadb_allocated_storage  = 1000
mysql_allocated_storage    = 100
