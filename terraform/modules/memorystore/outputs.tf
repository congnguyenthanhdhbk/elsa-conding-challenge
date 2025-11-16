output "instance_id" {
  description = "Redis instance ID"
  value       = google_redis_instance.instance.id
}

output "instance_name" {
  description = "Redis instance name"
  value       = google_redis_instance.instance.name
}

output "host" {
  description = "Redis host address"
  value       = google_redis_instance.instance.host
  sensitive   = true
}

output "port" {
  description = "Redis port"
  value       = google_redis_instance.instance.port
}

output "current_location_id" {
  description = "Current location ID"
  value       = google_redis_instance.instance.current_location_id
}

output "memory_size_gb" {
  description = "Memory size in GB"
  value       = google_redis_instance.instance.memory_size_gb
}

output "redis_version" {
  description = "Redis version"
  value       = google_redis_instance.instance.redis_version
}

output "auth_string" {
  description = "AUTH string for Redis (if auth enabled)"
  value       = google_redis_instance.instance.auth_string
  sensitive   = true
}
