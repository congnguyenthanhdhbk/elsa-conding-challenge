output "topic_ids" {
  description = "Map of topic IDs"
  value       = { for k, v in google_pubsub_topic.topics : k => v.id }
}

output "topic_names" {
  description = "Map of topic names"
  value       = { for k, v in google_pubsub_topic.topics : k => v.name }
}

output "subscription_ids" {
  description = "Map of subscription IDs"
  value       = { for k, v in google_pubsub_subscription.subscriptions : k => v.id }
}

output "subscription_names" {
  description = "Map of subscription names"
  value       = { for k, v in google_pubsub_subscription.subscriptions : k => v.name }
}

output "dead_letter_topic_ids" {
  description = "Map of dead letter topic IDs"
  value       = { for k, v in google_pubsub_topic.dead_letter_topics : k => v.id }
}
