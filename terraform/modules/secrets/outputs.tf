output "secret_ids" {
  description = "Map of secret IDs"
  value       = { for k, v in google_secret_manager_secret.secrets : k => v.id }
}

output "secret_names" {
  description = "Map of secret names"
  value       = { for k, v in google_secret_manager_secret.secrets : k => v.secret_id }
}

output "secret_version_ids" {
  description = "Map of secret version IDs"
  value       = { for k, v in google_secret_manager_secret_version.secret_versions : k => v.id }
  sensitive   = true
}
