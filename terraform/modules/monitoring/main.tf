# Cloud Monitoring Module

# Notification Channels
resource "google_monitoring_notification_channel" "channels" {
  for_each = { for idx, channel in var.notification_channels : idx => channel }

  display_name = each.value.display_name
  project      = var.project_id
  type         = each.value.type

  labels = each.value.labels

  enabled = true
}

# Alert Policies
resource "google_monitoring_alert_policy" "alert_policies" {
  for_each = var.alert_policies

  display_name = each.value.display_name
  project      = var.project_id
  enabled      = each.value.enabled
  combiner     = "OR"

  notification_channels = [
    for channel in google_monitoring_notification_channel.channels : channel.id
  ]

  conditions {
    display_name = each.value.display_name

    condition_threshold {
      filter          = each.value.filter
      duration        = each.value.conditions.duration
      comparison      = each.value.conditions.comparison
      threshold_value = each.value.conditions.threshold_value

      aggregations {
        alignment_period   = each.value.conditions.aggregation_period
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }

  documentation {
    content   = each.value.documentation
    mime_type = "text/markdown"
  }
}

# Uptime Checks
resource "google_monitoring_uptime_check_config" "uptime_checks" {
  for_each = var.uptime_checks

  display_name = each.value.display_name
  project      = var.project_id
  timeout      = each.value.timeout
  period       = each.value.period

  http_check {
    path         = each.value.http_check.path
    port         = each.value.http_check.port
    use_ssl      = each.value.http_check.use_ssl
    validate_ssl = each.value.http_check.validate_ssl
  }

  monitored_resource {
    type = each.value.monitored_resource.type
    labels = each.value.monitored_resource.labels
  }
}
