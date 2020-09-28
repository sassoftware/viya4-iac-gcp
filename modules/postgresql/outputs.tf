
output "postgres_server_private_ip" {
  description = "Private IP of the PostgreSQL server. Use this value to set DATABASE_HOST in your Viya deployment."
  value       = ( var.create_postgres ? 
                   ( length(google_sql_database_instance.utility-database) > 0 
                    ? google_sql_database_instance.utility-database[0].private_ip_address 
                    : null )
                : null )
}

