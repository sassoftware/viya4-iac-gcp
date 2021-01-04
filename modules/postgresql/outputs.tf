
output "postgres_server_private_ip" {
  description = "Private IP of the PostgreSQL server. Use this value to set DATABASE_HOST in your Viya deployment."
  value = (var.create_postgres ?
    (length(google_sql_database_instance.utility-database) > 0
      ? google_sql_database_instance.utility-database[0].private_ip_address
    : null)
  : null)
}

output "postgres_server_public_ip" {
  description = "Public IP of the PostgreSQL server. Use this value for client access."
  value = (var.create_postgres ?
    (length(google_sql_database_instance.utility-database) > 0
      ? google_sql_database_instance.utility-database[0].public_ip_address
    : null)
  : null)
}

output "postgres_server_name" {
  value = (var.create_postgres ?
    (length(google_sql_database_instance.utility-database) > 0
      ? google_sql_database_instance.utility-database[0].name
    : null)
  : null)
}
output "postgres_admin" {
  value = var.create_postgres ? var.administrator_login : null
}
output "postgres_password" {
  value = var.create_postgres ? var.administrator_password : null
}
output "postgres_server_id" {
  value = (var.create_postgres ?
    (length(google_sql_database_instance.utility-database) > 0
      ? google_sql_database_instance.utility-database[0].self_link
    : null)
  : null)
}
output "postgres_server_port" {
  value = var.create_postgres ? "5432" : null
}


