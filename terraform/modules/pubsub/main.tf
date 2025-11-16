# Cloud Pub/Sub Module

locals {
  topic_names = { for topic in var.topics : topic => "${topic}-${var.env}" }
}

# Topics
resource "google_pubsub_topic" "topics" {
  for_each = local.topic_names

  name    = each.value
  project = var.project_id
  labels  = var.labels

  message_retention_duration = "86400s" # 24 hours
}

# Dead Letter Topics
resource "google_pubsub_topic" "dead_letter_topics" {
  for_each = { for k, v in var.subscriptions : k => v if lookup(v, "dead_letter_topic", null) != null }

  name    = "${each.value.dead_letter_topic}-${var.env}"
  project = var.project_id
  labels  = merge(var.labels, { purpose = "dead-letter" })

  message_retention_duration = "604800s" # 7 days
}

# Subscriptions
resource "google_pubsub_subscription" "subscriptions" {
  for_each = var.subscriptions

  name    = "${each.key}-${var.env}"
  project = var.project_id
  topic   = google_pubsub_topic.topics[each.value.topic].id
  labels  = var.labels

  ack_deadline_seconds       = each.value.ack_deadline_seconds
  message_retention_duration = each.value.message_retention_duration
  retain_acked_messages      = each.value.retain_acked_messages
  enable_message_ordering    = each.value.enable_message_ordering

  expiration_policy {
    ttl = ""  # Never expire
  }

  dynamic "dead_letter_policy" {
    for_each = lookup(each.value, "dead_letter_topic", null) != null ? [1] : []
    content {
      dead_letter_topic     = google_pubsub_topic.dead_letter_topics[each.key].id
      max_delivery_attempts = each.value.max_delivery_attempts
    }
  }

  retry_policy {
    minimum_backoff = "10s"
    maximum_backoff = "600s"
  }
}
