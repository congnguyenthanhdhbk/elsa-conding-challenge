output "notification_channel_ids" {
  description = "Map of notification channel IDs"
  value       = { for k, v in google_monitoring_notification_channel.channels : k => v.id }
}

output "alert_policy_ids" {
  description = "Map of alert policy IDs"
  value       = { for k, v in google_monitoring_alert_policy.alert_policies : k => v.id }
}

output "uptime_check_ids" {
  description = "Map of uptime check IDs"
  value       = { for k, v in google_monitoring_uptime_check_config.uptime_checks : k => v.id }
}
