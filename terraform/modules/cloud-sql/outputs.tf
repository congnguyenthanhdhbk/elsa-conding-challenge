# Cloud SQL Module Outputs

output "instance_name" {
  description = "Cloud SQL instance name"
  value       = google_sql_database_instance.instance.name
}

output "instance_connection_name" {
  description = "Cloud SQL instance connection name (for Cloud SQL Proxy)"
  value       = google_sql_database_instance.instance.connection_name
}

output "connection_name" {
  description = "Cloud SQL connection name"
  value       = google_sql_database_instance.instance.connection_name
}

output "private_ip" {
  description = "Private IP address"
  value       = google_sql_database_instance.instance.private_ip_address
  sensitive   = true
}

output "database_name" {
  description = "Database name"
  value       = google_sql_database.database.name
}

output "user" {
  description = "Database user"
  value       = google_sql_user.user.name
}

output "db_password" {
  description = "Database password"
  value       = random_password.db_password.result
  sensitive   = true
}

output "self_link" {
  description = "Cloud SQL instance self link"
  value       = google_sql_database_instance.instance.self_link
}

output "ssl_cert" {
  description = "SSL certificate for client connections"
  value       = google_sql_ssl_cert.client_cert.cert
  sensitive   = true
}

output "ssl_cert_private_key" {
  description = "SSL certificate private key"
  value       = google_sql_ssl_cert.client_cert.private_key
  sensitive   = true
}

output "server_ca_cert" {
  description = "Server CA certificate"
  value       = google_sql_ssl_cert.client_cert.server_ca_cert
  sensitive   = true
}
