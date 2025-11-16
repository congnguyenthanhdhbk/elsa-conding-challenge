output "service_account_ids" {
  description = "Map of service account IDs"
  value       = { for k, v in google_service_account.service_accounts : k => v.id }
}

output "service_account_emails" {
  description = "Map of service account emails"
  value       = { for k, v in google_service_account.service_accounts : k => v.email }
}

output "service_account_unique_ids" {
  description = "Map of service account unique IDs"
  value       = { for k, v in google_service_account.service_accounts : k => v.unique_id }
}
